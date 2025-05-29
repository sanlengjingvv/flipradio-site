class FlipItemsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :update, :create ]
  skip_before_action :require_authentication, except: [ :update, :create ]

  def index
    if params[:title].present?
      @flip_items = FlipItem.where(title: params[:title])
    else
      @pagy, @flip_items = pagy(params[:query].present? ? FlipItem.search(params) : FlipItem.recent.all)
    end
  end

  def show
    @flip_item = FlipItem.find(params[:id])
  end

  def edit
    @flip_item = FlipItem.find(params[:id])
  end

  def update
    @flip_item = FlipItem.find(params[:id])
    respond_to do |format|
      if @flip_item.update!(flip_item_params)
        format.html { redirect_to @flip_item, notice: "flip_item was successfully updated." }
        format.json { render :show, status: :ok, location: @flip_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @flip_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @flip_item = FlipItem.new(flip_item_params)
    if @flip_item.save
      render :show, status: :ok, location: @flip_item
    else
      render json: @flip_item.errors, status: :unprocessable_entity
    end
  end

  def check_for_typos
    @flip_item = FlipItem.find(params[:id])
    prompt = <<-prompt
      You are an AI assistant tasked with analyzing a transcription of a speech audio that contains mostly Chinese. The content is primarily about Philosophy, Politics, and Economics. Your goal is to identify potential errors in the transcription and provide a structured JSON output of your findings.

      Here is the title of the speech:
      <title>
      #{@flip_item.title}
      </title>
      Here is the transcription of the speech:
      <transcription>
      #{@flip_item.content}
      </transcription>

      Please follow these steps to analyze the transcription:

      1. Read through the entire transcription carefully.
      2. The rap/poem sections at beginning and end is unrelated to the main philosophical lecture
      3. Identify any parts that seem incorrect or out of place, considering the context of Philosophy, Politics, and Economics.
      4. Pay special attention to areas where the language switches between Chinese and English, as these transitions may be prone to errors.
      5. Look for any inconsistencies in terminology, names, or concepts that don't align with common knowledge in the fields of Philosophy, Politics, and Economics.
      6. Consider any grammatical errors or unusual phrasing that might indicate a transcription mistake.

      After your analysis, provide your findings in a JSON format with the following structure:

      <output>
      {
        "potential_errors": [
          {
            "error_type": "string",
            "error_location": "string",
            "original_text": "string",
            "suggested_correction": "string",
            "confidence": number,
            "explanation": "string"
          }
        ],
        "overall_assessment": {
          "transcription_quality": "string",
          "major_issues": ["string"],
          "recommendations": ["string"]
        }
      }
      </output>

      For the "error_type" field, use one of the following categories: "Grammar", "Vocabulary", "Context", "Language Switch", or "Other".

      The "error_location" Should be the starting position of the character where the error occurred in the text.

      The "confidence" field should be a number between 0 and 1, representing your certainty about the error and suggested correction.

      In the "overall_assessment" section, provide a brief evaluation of the transcription quality (e.g., "Good", "Fair", "Poor"), list any major issues you've identified, and offer recommendations for improving the transcription process.

      If you're unsure about a potential error or correction, include it in the JSON output but assign a lower confidence score and explain your uncertainty in the "explanation" field.

      If you don't find any errors in the transcription, still provide the JSON output with an empty "potential_errors" array and fill in the "overall_assessment" section accordingly.

      Remember to base your analysis solely on the provided transcription and your knowledge of Philosophy, Politics, and Economics. Do not make assumptions about the audio content beyond what is presented in the transcription.
      prompt

      # RubyLLM.models.by_provider(:gemini).map(&:id)
      chat = Chat.create!(model_id: "gemini-2.0-flash")
      Rails.logger.debug chat.model_id
      response = chat.ask prompt
      @content = response.content
      Rails.logger.debug "Gemini response: #{response.content}"
      respond_to do |format|
        format.turbo_stream
      end
  end

  private
    # Only allow a list of trusted parameters through.
    def flip_item_params
      params.expect(flip_item: [ :title, :link, :content, :release_date ])
    end
end

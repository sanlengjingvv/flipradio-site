class CreateXyzfmItems < ActiveRecord::Migration[8.0]
  def change
    create_table :xyzfm_items do |t|
      t.string :title
      t.string :enclosure_url
      t.datetime :pub_date
      t.string :link

      t.timestamps
    end
  end
end

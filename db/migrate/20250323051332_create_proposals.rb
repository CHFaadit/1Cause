class CreateProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :proposals do |t|
      t.string :cause_title
      t.text :cause_description
      t.integer :funding_needed
      t.string :corporate_matching
      t.text :milestones
      t.text :impact

      t.timestamps
    end
  end
end

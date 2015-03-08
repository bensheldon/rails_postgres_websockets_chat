class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :author
      t.text :body

      t.timestamps null: false
    end

    add_index :messages, :created_at
  end
end

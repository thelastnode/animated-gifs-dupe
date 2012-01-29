mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId - Schema.ObjectId

Gif = new Schema(
  hash:
    type: String
    unique: true

  links: [
    type: String
  ]
)

exports.Gif = mongoose.models('Gif', Gif)
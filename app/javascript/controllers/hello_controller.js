import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('yes')
  }

  close() {
    console.log(this.element)
    this.element.remove()
  }
}

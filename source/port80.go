package main

import (
  "net/http"
)

func main() {
  http.Handle("/", http.FileServer(http.Dir("/tmp")))
  http.ListenAndServe(":80", nil)
}

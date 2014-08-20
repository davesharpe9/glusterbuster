package main

import (
  "fmt"
  "os"
  "strconv"
  "github.com/cloudfoundry/gosigar"
)

func main() {
  usage := sigar.FileSystemUsage{}
  usage.Get("/var")
  fmt.Println(strconv.FormatUint(usage.FreeFiles,10))
  for i, val := uint64(0), uint64(usage.FreeFiles); i < val; i++ {
    fd, err := os.Create(strconv.FormatUint(i,10))
    if err != nil {
      fmt.Printf("%+v", err)
      os.Exit(1)
    }
    erra := fd.Close();
    if erra != nil {
      fmt.Printf("%+v", erra)
      os.Exit(1)
    }
  }
}

package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/hashicorp/go-getter"
	"github.com/mitchellh/cli"
)

func GetCommandFactory() (cli.Command, error) {
	return &Get{}, nil
}

type Get struct {
}

func (c *Get) Help() string {
	helpText := `
Usage: basetool' get [options] url destination

  Fetches the given file into the given destination. This supports all of the
  URL formats offered by go-getter (see https://github.com/hashicorp/go-getter).
  Checksums may be verified by appending the query parameter ?checksum=sha256:<hash>
  to the URL (this won't be passed along during the fetch).
`
	return strings.TrimSpace(helpText)
}

func (c *Get) Synopsis() string {
	return "Fetch files using URLs"
}

func (c *Get) Run(args []string) int {
	cmdFlags := flag.NewFlagSet("get", flag.ContinueOnError)
	cmdFlags.Usage = func() { fmt.Printf(c.Help()) }
	if err := cmdFlags.Parse(args); err != nil {
		return 1
	}

	if len(cmdFlags.Args()) != 2 {
		fmt.Fprintf(os.Stderr, "Error: two arguments are required\n")
		return 1
	}

	url, destination := cmdFlags.Args()[0], cmdFlags.Args()[1]
	if err := getter.GetFile(destination, url); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to get '%s': %s\n", url, err)
		return 1
	}
	return 0
}

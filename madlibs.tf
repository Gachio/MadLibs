terraform {
    required_version = ">= 1.2.0"
    required_providers {
        random = {
            source = "hashicorp/random"
            version = "~> 3.0"
        }
        local = {
            source = "hashicorp/local"
            version = "~> 2.0"
        }
        archive = {
            source = "hashicorp/archive"
            version = "~> 2.0"
        }
    }
}

variable "story" {
    description = "A word pool to use for Mad Libs"
    type = object({
        nouns = list(string),
        adjectives = list(string),
        verbs = list(string),
        adverbs = list(string),
        numbers = list(number),
    })

    validation {
        condition = length(var.story["nouns"]) >= 10
        error_message = "At least 10 nouns must be supplied."
    }
}

variable "num_files" {
    default = 50
    type = number
}

locals {
    uppercase_story = {for k, v in var.story : k => [for s in v : upper(s)]}
    #v = length(var.words["nouns"])>=1 ? var.words["nouns"] : [][0]
}

locals {
    templates = tolist(fileset(path.module, "templates/*.txt"))
}

resource "local_file" "mad_libs" {
    count = var.num_files
    filename = "madlibs/madlibs-${count.index}.txt"
    content = templatefile(element(local.templates, count.index),
    {
        nouns = random_shuffle.random_nouns[count.index].result
        adjectives = random_shuffle.random_adjectives[count.index].result
        verbs = random_shuffle.random_verbs[count.index].result
        numbers = random_shuffle.random_numbers[count.index].result
        adverbs = random_shuffle.random_adverbs[count.index].result
    })
}

resource "random_shuffle" "random_nouns" {
    count = var.num_files
    input = local.uppercase_story["nouns"]
}

resource "random_shuffle" "random_adjectives" {
    count = var.num_files
    input = local.uppercase_story["adjectives"]
}

resource "random_shuffle" "random_verbs" {
    count = var.num_files
    input = local.uppercase_story["verbs"]
}

resource "random_shuffle" "random_adverbs" {
    count = var.num_files
    input = local.uppercase_story["adverbs"]
}

resource "random_shuffle" "random_numbers" {
    count = var.num_files
    input = local.uppercase_story["numbers"]
}

/*
output "mad_libs" {
    value = templatefile("${path.module}/templates/batman.txt",
        {
            nouns = random_shuffle.random_nouns.result
            adjectives = random_shuffle.random_adjectives.result
            verbs = random_shuffle.random_verbs.result
            adverbs = random_shuffle.random_adverbs.result
            numbers = random_shuffle.random_numbers.result
    })
}
*/

data "archive_file" "mad_libs" {
    depends_on = [local_file.mad_libs]
    type = "zip"
    source_dir = "${path.module}/madlibs"
    output_path = "${path.cwd}/madlibs.zip"
}


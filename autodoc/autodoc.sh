#!/bin/bash
FOLDER=$(pwd)

find "$FOLDER" -type f -name "*.tf" -exec sh -c '
    for TF_FOLDER do
        TF_FOLDER=$(dirname "$TF_FOLDER")
        
        terraform-docs markdown table --output-file "$TF_FOLDER/README.md" --output-mode inject "$TF_FOLDER"
        echo "Documentation created/updated for: $TF_FOLDER"
    done
' sh {} +
*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${TEMP_OUTPUT_DIRECTORY}=           ${OUTPUT_DIR}${/}temp
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${OUTPUT_DIR}${/}receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Set up directories
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Wait Until Keyword Succeeds
        ...    5x
        ...    0.5s
        ...    Fill the form    ${order}
    END
    Create ZIP package from PDF files
    Cleanup temporary PDF directory
    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    css:button.btn.btn-dark

Get orders
    Download the file
    ${table}=    Read table from CSV    ${TEMP_OUTPUT_DIRECTORY}${/}orders.csv
    RETURN    ${table}

Download the file
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    ${TEMP_OUTPUT_DIRECTORY}${/}orders.csv
    ...    overwrite=True

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    css:input[type="number"]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Sleep    150ms
    Wait Until Element Is Visible    id:robot-preview
    Screenshot
    ...    locator=id:robot-preview-image
    ...    filename=${TEMP_OUTPUT_DIRECTORY}${/}robot-preview-image-${order}[Order number].png
    Click Button    css:button.btn.btn-primary
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf
    ...    content=${order_receipt_html}
    ...    output_path=${TEMP_OUTPUT_DIRECTORY}${/}robot-order-${order}[Order number].pdf
    Add Watermark Image To PDF
    ...    image_path=${TEMP_OUTPUT_DIRECTORY}${/}robot-preview-image-${order}[Order number].png
    ...    source_path=${TEMP_OUTPUT_DIRECTORY}${/}robot-order-${order}[Order number].pdf
    ...    output_path=${PDF_TEMP_OUTPUT_DIRECTORY}${/}robot-order-${order}[Order number].pdf
    Click Button    css:#order-another

Set up directories
    Create Directory    ${OUTPUT_DIR}
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Create Directory    ${TEMP_OUTPUT_DIRECTORY}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True
    Remove Directory    ${TEMP_OUTPUT_DIRECTORY}    True

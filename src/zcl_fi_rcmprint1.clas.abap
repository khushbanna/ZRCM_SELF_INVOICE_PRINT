CLASS zcl_fi_rcmprint1 DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .

    CLASS-METHODS : read_posts
      IMPORTING VALUE(invoice)  TYPE string OPTIONAL
                company         TYPE string OPTIONAL
                fiscalyear      TYPE string OPTIONAL
      RETURNING VALUE(result12) TYPE string
      RAISING   cx_static_check .



  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_FI_RCMPRINT1 IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA(req) = request->get_form_fields(  ).
    response->set_header_field( i_name = 'Access-Control-Allow-Origin' i_value = '*' ).
    response->set_header_field( i_name = 'Access-Control-Allow-Credentials' i_value = 'true' ).

    DATA(companycode1) = VALUE #( req[ name = 'companycode' ]-value OPTIONAL ) .
    DATA(invoice1) = VALUE #( req[ name = 'invoiceno' ]-value OPTIONAL ) .
    DATA(invoicetype) = VALUE #( req[ name = 'invoicetype' ]-value OPTIONAL ) .
    DATA(currency) = VALUE #( req[ name = 'currency' ]-value OPTIONAL ) .
    DATA(fiscalyear) = VALUE #( req[ name = 'fiscalyear' ]-value OPTIONAL ) .


    DATA base64 TYPE string.
    DATA(pdf) = read_posts( invoice = invoice1
                            company = companycode1
*                        invoicetype = invoicetype
*                        currency = currency
                            fiscalyear = fiscalyear
                            ) .
    pdf   =  zdigi_sign_1=>get_digi_sign( pdf = pdf pd  = 'Y' )  .
    base64   =  zdigi_sign_1=>get_digi_sign( pdf = pdf  )  .
    response->set_text( base64  ).

  ENDMETHOD.


  METHOD read_posts .


    DATA(variable) = invoice  .


    IF variable IS NOT INITIAL .



      DATA: xml TYPE string.
      xml = xml &&
    |<form1>|.
********************************************************************************Copy code
      DATA count TYPE i.
      DATA textcopy TYPE string .

      count  = count + 1.
      IF count = 1.
        textcopy  = ' Original For Recipient     ' .
      ELSEIF
         count = 2.
        textcopy = 'Duplicate For Transporter' .
      ELSEIF
         count = 3.
        textcopy = 'Tripplicate For Supplier'.
      ELSEIF
         count = 4.
        textcopy = 'Extra Copy'.
      ENDIF.

      SELECT * FROM zfi_pic_data_for_tab_cds  WHERE companycode  =  @company AND accountingdocument = @invoice
      INTO TABLE  @DATA(it_tab).

      READ TABLE it_tab INTO DATA(wa12) INDEX 1.


      SELECT SINGLE in_hsnorsaccode FROM i_operationalacctgdocitem WHERE accountingdocument = @invoice
      AND companycode = @company AND fiscalyear = @fiscalyear AND costcenter <> '' INTO @DATA(hsncd).

      SELECT SINGLE branch FROM i_journalentry WHERE accountingdocument = @invoice
      AND companycode = @company AND fiscalyear = @fiscalyear INTO @DATA(businessplace).

      SELECT SINGLE postingdate FROM i_journalentry WHERE accountingdocument = @invoice
      AND companycode = @company AND fiscalyear = @fiscalyear INTO @DATA(post_date).

      SELECT SINGLE documentreferenceid FROM i_journalentry WHERE accountingdocument = @invoice
      AND companycode = @company AND fiscalyear = @fiscalyear INTO @DATA(doc_ref).

      SELECT SINGLE documentdate FROM i_journalentry WHERE accountingdocument = @invoice
      AND companycode = @company AND fiscalyear = @fiscalyear INTO @DATA(doc_dat).

      DATA doc_date TYPE char10.

      IF doc_dat IS NOT INITIAL.
        doc_date = doc_dat+4(2) && '/' && doc_dat+6(2)  && '/' && doc_dat+0(4).
      ENDIF.


      DATA : line1 TYPE string.
      DATA : line2 TYPE string.
      DATA : line3 TYPE string.
      DATA : line4 TYPE string.


      IF businessplace = 'TSHR'.

        line1 ='TS Tech Sun Rajasthan Pvt. Ltd.'.
        line2 ='Toyotsu Bharat Integrated Services Private Limited'.
        line3 ='Babra Bakipur, Gurugram, Haryana, India, Postal code - 122506'.
        line4 ='06AADCT0094P1ZZ'.

      ELSEIF businessplace = 'TSKA'.

        line1 ='TS Tech Sun Rajasthan Pvt. Ltd.'.
        line2 ='Building no 04  Bidadi IND. area Bengaluru'.
        line3 ='Karnataka, India, Postal code - 562109'.
        line4 ='29AADCT0094P1ZR'.

      ELSEIF businessplace = 'TSRJ'.

        line1 ='TS Tech Sun Rajasthan Pvt. Ltd.'.
        line2 ='SP2-5 AND 6, NIC Majrakath Japaness Zone'.
        line3 ='Kotputli, Behror, Rajasthan, India, Postal code - 301705'.
        line4 ='08AADCT0094P1ZV'.

      ELSEIF businessplace = 'TSGJ'.

        line1 ='TS Tech Sun Rajasthan Pvt. Ltd.'.
        line2 ='Plat no 28 to 45 MANDAL INDUSTRIAL ESTATE JAPANESE'.
        line3 ='Ahmedabad, Gujarat, India Pin code-382130'.
        line4 ='24AADCT0094P1Z1'.


      ENDIF.


      """""""""""""""""""""""""""CHANGES BY PRAKASH SINGH CHOUHAN""""""""""""""""""""

      xml = xml &&

         |<table>| &&
     "    |<inv>{ iv-a-BillingDocument }</inv>| &&
         |<Table1>| &&
             |<Row1>| &&
                |<table1subform>| &&
                |<top>| &&
                      |<Pageno>Si manu vacuas</Pageno>| &&
**                  |<taxinvoiceheadingcpy>Apros tres et quidem</taxinvoiceheadingcpy>| &&
                |</top>| &&
                   |<HIDEFIELD>| &&
      "             |<Count>{ count }</Count>| &&
*              |<Count>Mirum est</Count>| &&
                   |<QRCodeBarcode2></QRCodeBarcode2>| &&
*              |<QRCodeBarcode2>YTFUYG<QRCodeBarcode2/>| &&
                      |<billtoname>{ line1 }</billtoname>| &&
                      |<billtocode>{ line2 }</billtocode>| &&
*                  |<add>{ bilto1-c-Street }  { bilto1-c-StreetName }  { bilto1-c-StreetPrefixName1 }</add>| &&
                      |<add>{ line3 }</add>| &&
                      |<add1></add1>| &&
                      |<receivercity>GSTIN : { line4 }</receivercity>| &&
                      |<receiverstatecode></receiverstatecode>| &&
                      |<receiverstatename>{ wa12-address } { wa12-district } { wa12-city } { wa12-regionname1 } { wa12-state_code }</receiverstatename>| &&
                      |<receiverpanno>{ wa12-pan_no }</receiverpanno>| &&
                      |<eeceivergstin>{ wa12-gstin }</eeceivergstin>| &&

                      |<shippedtoname>{ wa12-name_of_recipient }</shippedtoname>| &&
                      |<shippedtocode>{ wa12-supplier }</shippedtocode>| &&
*                 |<shipptoadd>{ shipto1-c-Street }  { shipto1-c-StreetName }  { shipto1-c-StreetPrefixName1 }</shipptoadd>| &&
                      |<shipptoadd>{ wa12-address }</shipptoadd>| &&
                      |<shipptoadd1>{ wa12-district }</shipptoadd1>| &&
                      |<shippedtocity>{ wa12-city }</shippedtocity>| &&
                      |<shippedtostatecode>{ wa12-state_code }</shippedtostatecode>| &&
                      |<shippedtostatename>{ wa12-regionname1 }</shippedtostatename>| &&
                      |<shippedtopanno>{ wa12-pan_no }</shippedtopanno>| &&
                      |<shippedtogstin>{ wa12-gstin  }</shippedtogstin>| &&
                      |<master_add3>Mirum est</master_add3>| &&
                      |<PEACEOFSUPPLY>{ '' }</PEACEOFSUPPLY>| &&
                      |<master_add4>Proinde</master_add4>| &&
                      |<add2>{ wa12-companycode }</add2>| &&
                      |<shppedtoadd2>Si manu vacuas</shppedtoadd2>| &&
                      |<invoiceno1>{ '' } </invoiceno1>| &&
                      |<invoiceno>{ wa12-alternativereferencedocument }</invoiceno>| &&
                     |<invoicedate1>{ '' }</invoicedate1>| &&
*                 |<invoicedate>{ <WA12>-date_of_issue } { '' }</invoicedate>| &&  "commented by varsha
                     |<invoicedate>{ post_date } { '' }</invoicedate>| &&
                      |<invoicetime1>{ '' }</invoicetime1>| &&
*                  |<invoicetime>{ <WA12>-CreationTime }</invoicetime>| &&
                      |<invoicetime>{ doc_ref }</invoicetime>| &&
                      |<VendorInvoiceDate>{ doc_date }</VendorInvoiceDate>| &&
                      |<vendorcode>{ wa12-supplier }  { wa12-name_of_recipient  }</vendorcode>| &&
                     |<taxcode>{ wa12-tax_code }</taxcode>| &&
                     |<ponoanddate>{ wa12-purchasingdocument }</ponoanddate>| &&
                      |<MASTERADD1></MASTERADD1>| &&
                      |<MASTERADD2></MASTERADD2>| &&
                      |<MASTERADD3></MASTERADD3> | &&
                      |<MASTERADD4></MASTERADD4>| &&
                      |<gstrules>{ '' }</gstrules>| &&
*                  |<PlaceofSupply>{ <WA12>-RegionName1 }</PlaceofSupply>| &&
*                  |<PlaceofSupply>{ <WA12>-RegionName1 }</PlaceofSupply>| &&
                      |<master_add1>{ wa12-accountingdocument }</master_add1> | &&
                      |<master_add2></master_add2>| &&
                      |<add2>{ wa12-companycode }</add2>| &&
                     |<AgaInvoice>{ '' }</AgaInvoice>| &&
*                  |<Challantype>{ challan_type }</Challantype>| &&
*                  |<refno>{ ref-PurchaseOrderByCustomer }</refno>| &&    """"""""""""""
*                  |<refdate>{ po_date1 }</refdate>| &&
*                   |<taxinvoiceheading>{ invoiceheading }</taxinvoiceheading>| &&
                      |</HIDEFIELD>| &&
                      |<Table1>| &&
                      |<tabletitles>| &&
                        |<Table9>| &&
                           |<Row1>| &&
                              |<FOC></FOC>| &&
                           |</Row1>| &&
                           |<Row2>| &&
                              |<Currency>{ '(' }{ '' }{ ')' }</Currency>| &&
                           |</Row2>| &&
                         |</Table9>| &&
                         |<Table8>| &&
                           |<Row1>| &&
                             |<FOC></FOC>| &&
                           |</Row1>| &&
                           |<Row2/>| &&
                           |</Table8>| &&
                         |<Table2>| &&
                            |<Row1/>| &&
                            |<Row2>| &&
                               |<Table3>| &&
                                  |<Row1/>| &&
                               |</Table3>| &&
                            |</Row2>| &&
                        |</Table2>| &&
                         |<Table4>| &&
                            |<Row1/>| &&
                            |<Row2>| &&
                               |<Table5>| &&
                                  |<Row1/>| &&
                               |</Table5>| &&
                            |</Row2>| &&
                         |</Table4>| &&
                         |<Table6>| &&
                            |<Row1/>| &&
                            |<Row2>| &&
                               |<Table7>| &&
                                  |<Row1/>| &&
                               |</Table7>| &&
                            |</Row2>| &&
                         |</Table6>| &&
                      |</tabletitles>|.



      DATA xsml TYPE string .

      DATA co(2) TYPE n .
      DATA unit TYPE string.
      DATA total TYPE  string.



      IF wa12-rcm_igst = ''.

        total = wa12-amountincompanycodecurrency  + wa12-rcm_sgstf + wa12-rcm_sgstf.

      ELSE.

        IF wa12-taxblevalue < 0 .

          wa12-taxblevalue = wa12-taxblevalue * -1 .

        ENDIF.

        total = wa12-rcm_igst + wa12-amountincompanycodecurrency .

      ENDIF.



""""""""""""""""""""""""""""""""""""""""added by sakshi on 24th january, 2026"""""""""""""""""""""""""""""""""""""""""""

      SELECT SINGLE  a~amountincompanycodecurrency ,  b~gstrate , a~transactiontypedetermination FROM i_operationalacctgdocitem  AS a
      LEFT OUTER JOIN ztax_code_new  AS b  ON ( a~taxcode = b~taxcode )
                                        WHERE  a~accountingdocument = @invoice
                                     AND    a~transactiontypedetermination = 'JIC'
                                     AND    a~fiscalyear = @fiscalyear INTO    @DATA(cgstp)  .

      SELECT SINGLE   a~amountincompanycodecurrency , b~gstrate , a~transactiontypedetermination FROM i_operationalacctgdocitem AS a
       LEFT OUTER JOIN ztax_code_new  AS b ON ( a~taxcode = b~taxcode )
                               WHERE a~accountingdocument = @invoice
                            AND   a~transactiontypedetermination = 'JIS'
                            AND a~fiscalyear = @fiscalyear  INTO  @DATA(sgstp) .

      SELECT SINGLE  a~amountincompanycodecurrency , b~gstrate , a~transactiontypedetermination FROM i_operationalacctgdocitem AS a
      LEFT OUTER JOIN ztax_code_new  AS b ON ( a~taxcode = b~taxcode )
                              WHERE a~accountingdocument = @invoice  AND
                              a~transactiontypedetermination = 'JII'
                              AND a~fiscalyear = @fiscalyear INTO @DATA(igstp) .

TYPES: BEGIN OF ty_gst_combined,
         accountingdocument          TYPE belnr_d,
         accountingdocumentitem      TYPE buzei,
         fiscalyear                  TYPE gjahr,
         amountincompanycodecurrency TYPE wrbtr,
         igst_amount                 TYPE wrbtr,
         cgst_amount                 TYPE wrbtr,
         sgst_amount                 TYPE wrbtr,
         transactiontypedetermination Type string,
         glaccount                   TYPE string,
         gldesc                      TYPE string,
         gstrate    TYPE p LENGTH 5 DECIMALS 2,
       END OF ty_gst_combined.

DATA: lt_combined TYPE TABLE OF ty_gst_combined,
      ls_combined TYPE ty_gst_combined,
      bas TYPE  string,
      bas1 TYPE  string.

      SELECT a~accountingdocument, a~fiscalyear, a~accountingdocumentitemtype, a~financialaccounttype,
      a~taxitemacctgdocitemref, a~amountincompanycodecurrency, a~accountingdocumentitem, a~glaccount, b~glaccountlongname
      FROM i_operationalacctgdocitem as a
      LEFT OUTER JOIN i_glaccounttextrawdata as b on ( a~glaccount = b~GLAccount
      AND b~chartofaccounts = 'YCOA' AND b~language = 'E')
      WHERE accountingdocument = @invoice AND fiscalyear = @fiscalyear and companycode = @company
      AND taxitemacctgdocitemref IS NOT  INITIAL AND accountingdocumentitemtype NE 'T' AND financialaccounttype = 'S'
      INTO TABLE @DATA(it).

      READ TABLE it INTO DATA(wa) INDEX 1.

      SELECT a~accountingdocument, a~fiscalyear, a~transactiontypedetermination, a~amountincompanycodecurrency, a~taxitemacctgdocitemref
      FROM i_operationalacctgdocitem as a
      WHERE companycode = @company AND accountingdocument = @invoice AND fiscalyear = @fiscalyear AND transactiontypedetermination IN ( 'JII', 'JIC', 'JIS' )
      INTO TABLE @DATA(it_all_gst).

LOOP AT it INTO wa.

  ls_combined-accountingdocument = wa-accountingdocument.
  ls_combined-accountingdocumentitem = wa-AccountingDocumentItem.
  ls_combined-fiscalyear = wa-fiscalyear.
  ls_combined-amountincompanycodecurrency = wa-amountincompanycodecurrency.
  ls_combined-gldesc = wa-GLAccountLongName.

  CLEAR: ls_combined-igst_amount,
         ls_combined-cgst_amount,
         ls_combined-sgst_amount.

  LOOP AT it_all_gst INTO DATA(wa_gst)
    WHERE taxitemacctgdocitemref = wa-TaxItemAcctgDocItemRef.

    CASE wa_gst-transactiontypedetermination.
      WHEN 'JII'.
        ls_combined-igst_amount = wa_gst-amountincompanycodecurrency.
        ls_combined-transactiontypedetermination = wa_gst-TransactionTypeDetermination.
      WHEN 'JIC'.
        ls_combined-cgst_amount = wa_gst-amountincompanycodecurrency.
       ls_combined-transactiontypedetermination = wa_gst-TransactionTypeDetermination.
      WHEN 'JIS'.
        ls_combined-sgst_amount = wa_gst-amountincompanycodecurrency.
       ls_combined-transactiontypedetermination = wa_gst-TransactionTypeDetermination.
    ENDCASE.

  ENDLOOP.

  APPEND ls_combined TO lt_combined.
  CLEAR: ls_combined, wa.

ENDLOOP.


LOOP AT lt_combined INTO ls_combined.

    CASE ls_combined-transactiontypedetermination.
      WHEN 'JII'.  " IGST
        bas1 = igstp-gstrate.
      WHEN 'JIC'.  " CGST
        bas = cgstp-gstrate.
      WHEN 'JIS'.  " SGST
        bas = cgstp-gstrate.
    ENDCASE.

  xml = xml &&
    |<tablevalues>| &&
    |<sno>{ sy-tabix }</sno>| &&
    |<descriptionofgoods>{ ls_combined-gldesc }</descriptionofgoods>| &&
    |<hsncode>{ hsncd }</hsncode>| &&
    |<qnty>{ wa12-quantity }</qnty>| &&
    |<unit>{ wa12-baseunit }</unit>| &&
    |<rate>{ wa12-amountincompanycodecurrency }</rate>| &&
    |<basicvalue>{ ls_combined-amountincompanycodecurrency }</basicvalue>| &&
    |<taxablevalue>{ ls_combined-amountincompanycodecurrency }</taxablevalue>| &&
    |<percentcgst>{ bas }</percentcgst>| &&
    |<amountcgst>{ ls_combined-cgst_amount }</amountcgst>| &&
    |<percentsgst>{ bas }</percentsgst>| &&
    |<amountsgst>{ ls_combined-sgst_amount }</amountsgst>| &&
    |<percentigst>{ bas1 }</percentigst>| &&
    |<amountigst>{ ls_combined-igst_amount }</amountigst>| &&
    |<totalamount>{ ls_combined-amountincompanycodecurrency }</totalamount>| &&
    |</tablevalues>|.

  CLEAR : ls_combined, ls_combined-gstrate, bas, bas1.

ENDLOOP.

""""""""""""""""""""""""""""""""""""""ended by sakshi on 27th january, 2026""""""""""""""""""""""""""""""""""""""""""""



      """"""""""""""""""""""""""""""""""""""""""ADDED BY VINOD SINGH CHOUHAN"""""""""""""""""""""""""

      xml = xml &&

                        |<totalrow>| &&
                         |<totalqnty></totalqnty>| &&
                         |<totalbasicvalue></totalbasicvalue>| &&
                         |<Totaloftaxable></Totaloftaxable>| &&
                         |<totalcgstamount></totalcgstamount>| &&
                         |<totalsgstamount></totalsgstamount>| &&
                         |<totaligstamount></totaligstamount>| &&
                         |<alltotalamount></alltotalamount>| &&
                      |</totalrow>| &&
                   |</Table1>| &&
                   |<address2>| &&
                   |<ADDRESS11>{ wa12-name_of_recipient }</ADDRESS11>| &&
                      |<IRNnumber></IRNnumber>| &&
                      |<acknumber>{ ':' } { '' }</acknumber>| &&
                      |<DateTimeField1>{ ':' } { '' }</DateTimeField1>| &&
                      |<ADDRESS22>{ wa12-address } { wa12-district } { wa12-regionname1 }</ADDRESS22>| &&
                      |<ADDRESS33> State Code: { wa12-state_code }    State Name: { wa12-regionname1 }</ADDRESS33>| &&
                      |<ADDRESS44> Phone Number : { wa12-phonenumber1 }</ADDRESS44>| &&
                      |<ADRESS55></ADRESS55>| &&
                      |<GSTIN11>{ wa12-gstin }</GSTIN11>| &&
                      |<supplyyyy> Place Of Supply :- Rajasthan </supplyyyy>| &&
*                  |<ewaybillnodate>{ ':' } { wt-a-Ebillno }  { GV1 }</ewaybillnodate>| &&
*                  |<modeoftransport>{ ':' } { transmode }</modeoftransport>| &&
*                  |<transportername>{ ':' } { tranporter }</transportername>| &&
                      |<vehicalregnno>{ ':' } { '' }</vehicalregnno>| &&
                      |<saleorderno>{ ':' } { '' }</saleorderno>| &&
                      |<Deliveryno>{ ':' } { '' }</Deliveryno>| &&
                   |</address2>| &&
                   |<table2subform>| &&
                      |<Table2>| &&
                         |<freightlrow>| &&
*                        |<freighttaxable>{ freight }</freighttaxable>| &&
                            |<freightratecgst>{ '' }</freightratecgst>| &&
                            |<freighamountcgst>{ '' }</freighamountcgst>| &&
                            |<freightratesgst>{ '' }</freightratesgst>| &&
                            |<freightamountsgst>{ '' }</freightamountsgst>| &&
                            |<freightrateigst>{ '' }</freightrateigst>| &&
                            |<freightamountigst>{ '' }</freightamountigst>| &&
                            |<freighttotalamount></freighttotalamount>| &&
                         |</freightlrow>| &&
                         |<insurancerow>| &&
*                        |<insurancetaxable>{ ins }</insurancetaxable>| &&
                            |<insuranceratecgst>{ '' }</insuranceratecgst>| &&
                            |<insuranceamountcgst>{ '' }</insuranceamountcgst>| &&
                            |<insuranceratesgst>{ '' }</insuranceratesgst>| &&
                            |<insuranceamountsgst>{ '' }</insuranceamountsgst>| &&
                            |<insurancerateigst>{ '' }</insurancerateigst>| &&
                            |<insuranceamountigst>{ '' }</insuranceamountigst>| &&
                            |<insurancetotalamount></insurancetotalamount>| &&
                         |</insurancerow>| &&
                         |<packingandforwardingrow>| &&
                            |<pandftax></pandftax>| &&
                            |<pandfratecgst>{ '' }</pandfratecgst>| &&
                            |<pandfamountcgst></pandfamountcgst>| &&
                            |<pandfratesgst>{ '' }</pandfratesgst>| &&
                            |<pandfamountsgst></pandfamountsgst>| &&
                            |<pandfrateigst>{ '' }</pandfrateigst>| &&
                            |<pandfamountigst></pandfamountigst>| &&
                            |<pandftotalamount></pandftotalamount>| &&
                         |</packingandforwardingrow>| &&
                         |<totalrow>| &&
                            |<totalamountcgst>{ '' }</totalamountcgst>| &&
                            |<totalamountsgst>{ '' }</totalamountsgst>| &&
                            |<totalamountigst>{ '' }</totalamountigst>| &&
                            |<totaloftotalamont></totaloftotalamont>| &&
                         |</totalrow>| &&
                      |</Table2>| &&
                   |</table2subform>| &&
                   |<freightsubform>| &&
                      |<Table3>| &&
                         |<tcsRow>| &&
                            |<totaltaxablevalue>{ '' }</totaltaxablevalue>| &&
                         |</tcsRow>| &&
                         |<totalbillinfigurerow>| &&
                            |<totalbillvalueinfigure></totalbillvalueinfigure>| &&
                         |</totalbillinfigurerow>| &&
                         |<totalbillinwords>| &&
                            |<totalbillvalueinwords></totalbillvalueinwords>| &&
                         |<amountinwords>{ wa-amountincompanycodecurrency  }</amountinwords>|  &&
                         |</totalbillinwords>| &&
                         |<totaltaxamtrow>| &&
                            |<totaltaxamt></totaltaxamt>| &&
                            |<currencyinr>{ '' }</currencyinr>| &&
                            |<PrintType></PrintType>| &&
                         |</totaltaxamtrow>| &&
                      |</Table3>| &&
                   |</freightsubform>| &&
*               |<CustGroupText>{ CustGroupText }</CustGroupText>| &&
*               |<Canceldoc>{ watermark }</Canceldoc>| &&
                   |<customgroup>{ '' }</customgroup>| &&
                   |<Dist.chanel>{ '' }</Dist.chanel>| &&
                   |<cancelled>{ '' }</cancelled>| &&
                   |<specialinstruction>{ '' }</specialinstruction>| &&
                   |<matdes>{ '' }{ '' }</matdes>| &&
                   |<qty>{ '' }{ '' }</qty>| &&
                   |<sign>| &&
                      |<preparedby>{ '' }</preparedby>| &&
                   |</sign>| &&
                   |<terms/>| &&
                   |<Subform10/>| &&
                    |<orderno>{ '' }</orderno>| &&  """""""""""""""""""""add by sandeep
                    |<QRCode>{ '' }</QRCode>| &&
                    |<invoiceno>{ '' }</invoiceno>| &&   """""""""""""""""""""""""""""""""""""
                |</table1subform>| &&
             |</Row1>| &&
          |</Table1>| &&
          |</table>|  .

      CLEAR : bas , bas1.
*ENDLOOP.


      xml = xml &&
     |</form1>|.


      REPLACE ALL OCCURRENCES OF '&' IN xml WITH 'and'.

*************************************************************************************************
      "   'GS_MULTIINV/GS_MULTIINV'   'GS_FINAL_INVOICE/GS_FINAL_INVOICE'
      result12   = ycl_test_adobe=>getpdf( template = 'ZSD_GS_MULTIINV2'  xmldata = xml   )  .


      """""""""""""""""""""""""""CHANGES BY PRAKASH SINGH CHOUHAN""""""""""""""""""""



    ENDIF.
  ENDMETHOD.
ENDCLASS.

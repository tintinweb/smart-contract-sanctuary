/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

contract Taxes {

    uint tax_percentage = 10;

    address payable tax_collector = payable(0x7615Cf5A8cC57179904B1914DDb22EA7493b44E6);



    function pay (address payable beneficiary) payable public {

        uint tax = msg.value * tax_percentage/100;

        beneficiary.transfer(msg.value - tax_percentage);

        tax_collector.transfer(tax);
            }  

}
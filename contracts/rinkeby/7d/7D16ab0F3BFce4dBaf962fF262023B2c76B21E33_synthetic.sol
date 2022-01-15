/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.8.0;

contract synthetic {

    mapping  ( address => bool ) public analystEntry ;
    string []  addressBook;
    mapping (string => uint) public stockToArrayPosition;
    mapping (address => mapping ( bool => uint [])) public selectedStock;//WINNER =>
    mapping (address => mapping (uint => uint)) public investedAmount;
    function addresses(string memory name) external {
        addressBook.push(name);
        stockToArrayPosition[name] = addressBook.length-1;
    }

    function entryAnalyst () external {
        require (analystEntry[msg.sender] == false);
        analystEntry[msg.sender] = true;
    }

    function selectStock(bool whichStock, uint[] memory slotNumber) external{
        require (analystEntry[msg.sender]== true, "Not registered");
        for (uint i;i<slotNumber.length;i++) {
            selectedStock[msg.sender][whichStock].push(slotNumber[i]);
        }
    }

    function investToStocksSelected(uint[] memory _amount, bool whichStock) external {
        require (analystEntry[msg.sender]== true, "Not registered");
        require (selectedStock[msg.sender][whichStock].length > 0, "No Stocks Selected");

        for (uint i=0;i<_amount.length;i++) {
            investedAmount[msg.sender][selectedStock[msg.sender][whichStock][i]]=_amount[i];
            //tokenTransfer
        }
    }


}
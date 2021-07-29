/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity 0.4.18;

 

contract BEC_Vuln {

    mapping (address=>uint) balances; 

 

    function batchTransfer(address[] memory _receivers, uint256 _value) public payable returns (bool) {

        uint cnt = _receivers.length;

        uint256 amount = uint256(cnt) * _value;

        require(cnt > 0 && cnt <= 20);

        require(_value > 0 && balances[msg.sender] >= amount);

   

        balances[msg.sender] = balances[msg.sender] - amount;

        for (uint i = 0; i < cnt; i++) {

            balances[_receivers[i]] = balances[_receivers[i]] + _value;

            //transfer(msg.sender, _receivers[i], _value);

        }

        return true;

     }

    

        function deposit() public payable{

            balances[msg.sender] = msg.value;

    }

 

        function getBalance() public view returns (uint){

            return balances[msg.sender];

    }

}



contract Token {

 mapping(address => uint) balances;

 function transfer(address _to, uint _value) public {
   require(balances[msg.sender] - _value >= 0);
   balances[msg.sender] -= _value;
   balances[_to] += _value;
 }
}
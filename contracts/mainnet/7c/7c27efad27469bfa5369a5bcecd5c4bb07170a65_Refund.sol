pragma solidity ^0.4.18;


contract Refund {

    address owner;

    function Refund() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    mapping (address => uint256) public balances;

    function add_addys(address[] _addys, uint256[] _values) onlyOwner {
        for (uint i = 0; i < _addys.length ; i++) {
            balances[_addys[i]] += (_values[i]);
        }
    }

    function refund() {
        uint256 eth_to_withdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(eth_to_withdraw);
    }

    function direct_refunds(address[] _addys, uint256[] _values) onlyOwner {
        for (uint i = 0; i < _addys.length ; i++) {
            uint256 to_refund = (_values[i]);
            balances[_addys[i]] = 0;
            _addys[i].transfer(to_refund);
        }
    }

    function change_specific_addy(address _addy, uint256 _val) onlyOwner {
        balances[_addy] = (_val);
    }

    function () payable {}

    function withdraw_ether() onlyOwner {
        owner.transfer(this.balance);
    }
}
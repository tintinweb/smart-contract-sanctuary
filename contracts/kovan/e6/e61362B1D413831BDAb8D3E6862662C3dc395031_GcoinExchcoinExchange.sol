/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-03
*/

pragma solidity ^0.7.4;

interface ERC20 {

    function totalSupply() virtual external view returns (uint256);
    function balanceOf(address _owner) virtual external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual external returns (bool success);
    function approve(address _spender, uint256 _value) virtual external returns (bool success);
    function allowance(address _owner, address _spender) virtual external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract GcoinExchcoinExchange {

    ERC20 gcoin;
    ERC20 exchcoin;
    address public Gcoin_Contract;
    address public Exchcoin_Contract;
    address public pltf_owner;
    mapping(address => uint256) public Gcoin_Ledger;
    mapping(address => uint256) public Exchcoin_Ledger;
    mapping (address => bool) public companyList;
    

    constructor(address _g, address _e, address _o) {
        Gcoin_Contract = _g;
        Exchcoin_Contract = _e;
        gcoin = ERC20(Gcoin_Contract);
        exchcoin = ERC20(Exchcoin_Contract);
        pltf_owner = _o;
    }

    function exchcoinToGcoin (uint256 _v) public {
        require(exchcoin.allowance(msg.sender, address(this)) >= _v, "allowance not enough");
        require(exchcoin.balanceOf(msg.sender) >= _v, "Insufficient exchcoin balance of user");
        require (Gcoin_Ledger[msg.sender] == 0, "There is unreceived balance in the Gcoin ledger");
        require (gcoin.balanceOf(address(this)) >= _v, "Contract don't have enough Gcoin to pay");
        bool success = exchcoin.transferFrom(msg.sender, address(this), _v);
        require(success == true, "failed to transfer Gcoin from user account to contract");
        Gcoin_Ledger[msg.sender] = _v;
        exchcoinToGcoinCoinDeliver();
    }

    function exchcoinToGcoinCoinDeliver() public {
        uint256 _v = Gcoin_Ledger[msg.sender];
        require(_v > 0, "Please send exchcoin to this smart constract first.");
        bool success = gcoin.transfer(msg.sender, _v);
        require (success == true, "Gcoin deliver failed, try to call CoinDeliver function again");
        Gcoin_Ledger[msg.sender] = 0;
    }

    function GcoinToExchcoin (uint256 _v) public {
        require(companyList[msg.sender] == true, "permission denied, only registered account can withdraw Exchcoin");
        require(gcoin.allowance(msg.sender, address(this)) >= _v, "allowance not enough");
        require(gcoin.balanceOf(msg.sender) >= _v, "Insufficient Gcoin balance of user");
        require(exchcoin.balanceOf(address(this)) >= _v, "Contract don't have enough Exchcoin saving");
        bool success = gcoin.transferFrom(msg.sender, address(this), _v);
        require(success = true, "failed to transfer Gcoin from user account to contract");
        Exchcoin_Ledger[msg.sender] = _v;
        GcointoExchcoinCoinDeliver();
    }

    function GcointoExchcoinCoinDeliver() public{
        uint256 _v = Exchcoin_Ledger[msg.sender];
        require(_v > 0, "Please send Gcoin to this smart contract first.");
        bool success = exchcoin.transfer(msg.sender, _v);
        require (success == true, "Exchcoin deliver failed, try to call CoinDeliver function again");
        Exchcoin_Ledger[msg.sender] = 0;
    }
    
    function registerCompany(address _a, bool _b) public {
        require(msg.sender == pltf_owner, "require to be platform owner");
        companyList[_a] = _b;
    }

    function checkGcoinBalance() public view returns (uint256) {
        return gcoin.balanceOf(msg.sender);
    }

    function checkExchcoinBalance() public view returns (uint256) {
        return exchcoin.balanceOf(msg.sender);
    }

    function checkSCGcoinLedger() public view returns (uint256) {
        return Gcoin_Ledger[msg.sender];
    }

    function checkSCExchcoinLedger() public view returns (uint256) {
        return Exchcoin_Ledger[msg.sender];
    }

}
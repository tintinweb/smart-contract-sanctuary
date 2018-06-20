pragma solidity ^0.4.18;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external; // Some ERC20 doesn&#39;t have return
    function transferFrom(address _from, address _to, uint _value) external; // Some ERC20 doesn&#39;t have return
    function approve(address _spender, uint _value) external; // Some ERC20 doesn&#39;t have return
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface BancorContract {
    /**
        @dev converts the token to any other token in the bancor network by following a predefined conversion path
        note that when converting from an ERC20 token (as opposed to a smart token), allowance must be set beforehand

        @param _path        conversion path, see conversion path format in the BancorQuickConverter contract
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn)
        external
        payable
        returns (uint256);
}


contract TestBancorTradeBNBETH {
    event Trade(uint256 srcAmount, uint256 destAmount);
    
    BancorContract public bancorTradingContract = BancorContract(0x8FFF721412503C85CFfef6982F2b39339481Bca9);
    
    function trade(address[] _path, uint256 _amount, uint256 _minReturn) {
        ERC20 src = ERC20(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
        src.approve(bancorTradingContract, _amount);
        
        uint256 destAmount = bancorTradingContract.quickConvert(_path, _amount, _minReturn);
        
        Trade(_amount, destAmount);
    }
    
    function getBack() {
        msg.sender.transfer(this.balance);
    }
    
    function getBack2() {
        ERC20 src = ERC20(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
        src.transfer(msg.sender, src.balanceOf(this));
    }
    
    // Receive ETH in case of trade Token -> ETH, will get ETH back from trading proxy
    function () public payable {

    }
}
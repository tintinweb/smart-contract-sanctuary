pragma solidity ^0.4.22;


// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface KyberNetwork {
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId) external payable returns(uint);
}


contract KyberPayWrapper {
    ERC20 constant public ETH_TOKEN_ADDRESS =
        ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event ProofOfPayment(address _beneficiary, address _token, uint _amount, bytes _data);

    function pay(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId,
        bytes paymentData,
        bytes hint,
        KyberNetwork kyberNetworkProxy
    ) public payable
    {
        hint;
        uint paidAmout;
        
        if(src == dest) {
            paidAmout = srcAmount;
            
            if(src == ETH_TOKEN_ADDRESS) destAddress.transfer(msg.value);
            else require(src.transferFrom(msg.sender,destAddress,srcAmount));
        }
        else {
            if(src != ETH_TOKEN_ADDRESS) {
                require(src.transferFrom(msg.sender,this,srcAmount));
                require(src.approve(kyberNetworkProxy,0));
                require(src.approve(kyberNetworkProxy,srcAmount));                
            }
            
            paidAmout = kyberNetworkProxy.trade(src,srcAmount,dest,destAddress,
                                                maxDestAmount,minConversionRate,
                                                walletId);
        }
        
        // log as event
        emit ProofOfPayment(msg.sender,dest,paidAmout,paymentData);
    }
}
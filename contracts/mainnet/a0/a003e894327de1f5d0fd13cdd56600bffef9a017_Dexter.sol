pragma solidity 0.4.23;

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract AirSwapExchangeI {
    function fill(address makerAddress, uint makerAmount, address makerToken,
                  address takerAddress, uint takerAmount, address takerToken,
                  uint256 expiration, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable;
}

contract KyberNetworkI {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
}

contract EtherDelta {
    function deposit() payable;
    function withdraw(uint amount);
    function depositToken(address token, uint amount);
    function withdrawToken(address token, uint amount);
    function balanceOf(address token, address user) constant returns (uint);
    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount);
    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
}

contract BancorConverterI {
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        returns (uint256);
}

/*
 * Dexter connects up EtherDelta, Kyber, Airswap, Bancor so trades can be proxied and a fee levied.
 * The purpose of this is to backfill the sell side of order books so there is always some form of liqudity available.
 *
 * This contract was written by Arctek, for Bamboo Relay.
 */
contract Dexter {
    address public owner;
    uint256 public takerFee;

    constructor() public {
        owner = msg.sender;
    }

    function () public payable {
        // need this for ED withdrawals
    }

    function kill() public {
        require(msg.sender == owner);

        selfdestruct(msg.sender);
    }

    function setFee(uint256 _takerFee) public returns (bool success) {
        require(owner == msg.sender);
        require(takerFee != _takerFee);

        takerFee = _takerFee;

        return true;
    }

    function setOwner(address _owner) public returns (bool success) {
        require(owner == msg.sender);
        require(owner != _owner);

        owner = _owner;

        return true;
    }

    function withdraw() public returns (bool success) {
        require(owner == msg.sender);
        require(address(this).balance > 0);

        msg.sender.transfer(address(this).balance);

        return true;
    }

    function withdrawTokens(ERC20Interface erc20) public returns (bool success) {
        require(owner == msg.sender);
        
        uint256 balance = erc20.balanceOf(this);

        // Sanity check in case the contract does not do this
        require(balance > 0);

        require(erc20.transfer(msg.sender, balance));

        return true;
    }

    // In case it needs to proxy later in the future
    function approve(ERC20Interface erc20, address spender, uint tokens) public returns (bool success) {
        require(owner == msg.sender);

        require(erc20.approve(spender, tokens));

        return true;
    }

    function tradeAirswap(
        address makerAddress, 
        uint makerAmount, 
        address makerToken,
        uint256 expirationFinalAmount, 
        uint256 nonceFee, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        payable
        returns (bool success)
    {
        // Fill the order, always ETH, since we can&#39;t withdraw from the user unless authorized
        AirSwapExchangeI(0x8fd3121013A07C57f0D69646E86E7a4880b467b7).fill.value(msg.value)(
            makerAddress, 
            makerAmount, 
            makerToken, 
            0x28b7d7B7608296E0Ee3d77C242F1F3ac571723E7, 
            msg.value, 
            address(0),
            expirationFinalAmount, 
            nonceFee, 
            v, 
            r, 
            s
        );

        if (takerFee > 0) {
            nonceFee = (makerAmount * takerFee) / (1 ether);

            expirationFinalAmount = makerAmount - nonceFee;//;
        }
        else {
            expirationFinalAmount = makerAmount;
        }

        require(ERC20Interface(makerToken).transferFrom(0x28b7d7B7608296E0Ee3d77C242F1F3ac571723E7, msg.sender, expirationFinalAmount));

        return true;
    }

    function tradeKyber(
        address dest,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId
    )
        public
        payable
        returns (bool success)
    {
        uint256 actualDestAmount = KyberNetworkI(0x964F35fAe36d75B1e72770e244F6595B68508CF5).trade.value(msg.value)(
            0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee, // eth token in kyber
            msg.value,
            dest, 
            this,
            maxDestAmount,
            minConversionRate,
            walletId
        );

        uint256 transferAmount;

        if (takerFee > 0) {
            uint256 fee = (actualDestAmount * takerFee) / (1 ether);

            transferAmount = actualDestAmount - fee;
        }
        else {
            transferAmount = actualDestAmount;
        }

        require(ERC20Interface(dest).transfer(msg.sender, transferAmount));

        return true;
    }

    function widthdrawEtherDelta(uint256 amount) public returns (bool success) {
        // withdraw dust
        EtherDelta etherDelta = EtherDelta(0x8d12A197cB00D4747a1fe03395095ce2A5CC6819);

        etherDelta.withdraw(amount);

        return true;
    }

    //ed trade
    function tradeEtherDelta(
        address tokenGet, 
        uint256 amountGetFee,
        address tokenGive,
        uint256 amountGive, 
        uint256 expiresFinalAmount, 
        uint256 nonce, 
        address user, 
        uint8 v, 
        bytes32 r, 
        bytes32 s, 
        uint256 amount,
        uint256 withdrawAmount
    )
        public
        payable
        returns (bool success)
    {
        EtherDelta etherDelta = EtherDelta(0x8d12A197cB00D4747a1fe03395095ce2A5CC6819);

        // deposit
        etherDelta.deposit.value(msg.value)();

        // trade throws if it can&#39;t match
        etherDelta.trade(
            tokenGet, 
            amountGetFee, 
            tokenGive, 
            amountGive,
            expiresFinalAmount, 
            nonce, 
            user,
            v, 
            r, 
            s, 
            amount
        );

        etherDelta.withdrawToken(tokenGive, withdrawAmount);

        if (takerFee > 0) {
            // amountGetFee
            amountGetFee = (withdrawAmount * takerFee) / (1 ether);

            expiresFinalAmount = withdrawAmount - amountGetFee;
        }
        else {
            expiresFinalAmount = withdrawAmount;
        }

        require(ERC20Interface(tokenGive).transfer(msg.sender, expiresFinalAmount) != false);

        return true;
    }

    function tradeBancor(address[] _path, uint256 _amount, uint256 _minReturn, address _token)
        public
        payable
        returns (bool success)
    {
        uint256 actualAmount = BancorConverterI(0xc6725aE749677f21E4d8f85F41cFB6DE49b9Db29).quickConvert.value(msg.value)(
            _path,
            _amount,
            _minReturn
        );

        uint256 transferAmount;

        if (takerFee > 0) {
            uint256 fee = (actualAmount * takerFee) / (1 ether);

            transferAmount = actualAmount - fee;
        }
        else {
            transferAmount = actualAmount;
        }

        require(ERC20Interface(_token).transfer(msg.sender, transferAmount));

        return true;
    }
}
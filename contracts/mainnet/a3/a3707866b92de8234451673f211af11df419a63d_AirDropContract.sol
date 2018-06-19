pragma solidity 0.4.21;

/// @title ERC20 ERC20 Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Chenyo
contract ERC20 {
    uint public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract AirDropContract {

    event AirDropped(address addr, uint amount);

    function drop(
        address tokenAddress,
        address conTokenAddress,  //额外token条件地址,如不需要,保持和tokenAddress相同即可
        uint amount,
        uint[2] minmaxTokenBalance,
        uint[2] minmaxConBalance,  //额外token min-max条件
        uint[2] minmaxEthBalance,
        address[] recipients) public {

        require(tokenAddress != 0x0);
        require(conTokenAddress != 0x0);
        require(amount > 0);
        require(minmaxTokenBalance[1] >= minmaxTokenBalance[0]);
        require(minmaxConBalance[1] >= minmaxConBalance[0]);
        require(minmaxEthBalance[1] >= minmaxEthBalance[0]);

        ERC20 token = ERC20(tokenAddress);
        ERC20 contoken = ERC20(conTokenAddress);

        uint balance = token.balanceOf(msg.sender);
        uint allowance = token.allowance(msg.sender, address(this));
        uint available = balance > allowance ? allowance : balance;

        for (uint i = 0; i < recipients.length; i++) {
            require(available >= amount);
            address recipient = recipients[i];
            if (isQualitifiedAddress(
                token,
                contoken,
                recipient,
                minmaxTokenBalance,
                minmaxConBalance,
                minmaxEthBalance
            )) {
                available -= amount;
                require(token.transferFrom(msg.sender, recipient, amount));

                AirDropped(recipient, amount);
            }
        }
    }

    function isQualitifiedAddress(
        ERC20 token,
        ERC20 contoken,
        address addr,
        uint[2] minmaxTokenBalance,
        uint[2] minmaxConBalance,
        uint[2] minmaxEthBalance
        )
        public
        view
        returns (bool result)
    {
        result = addr != 0x0 && addr != msg.sender && !isContract(addr);

        uint ethBalance = addr.balance;
        uint tokenBbalance = token.balanceOf(addr);
        uint conTokenBalance = contoken.balanceOf(addr);

        result = result && (ethBalance>= minmaxEthBalance[0] &&
            ethBalance <= minmaxEthBalance[1] &&
            tokenBbalance >= minmaxTokenBalance[0] &&
            tokenBbalance <= minmaxTokenBalance[1] &&
            conTokenBalance >= minmaxConBalance[0] &&
            conTokenBalance <= minmaxConBalance[1]);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function () payable public {
        revert();
    }
}
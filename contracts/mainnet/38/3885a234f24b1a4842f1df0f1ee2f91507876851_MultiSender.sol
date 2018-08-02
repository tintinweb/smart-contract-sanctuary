pragma solidity ^0.4.24;

contract ERC20 {
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MultiSender {
    using SafeMath for uint256;

    function multiSend(address tokenAddress, address[] addresses, uint256[] amounts) public payable {
        require(addresses.length <= 100);
        require(addresses.length == amounts.length);
        if (tokenAddress == 0x000000000000000000000000000000000000bEEF) {
            multisendEther(addresses, amounts);
        } else {
            ERC20 token = ERC20(tokenAddress);
            //Token address
            for (uint8 i = 0; i < addresses.length; i++) {
                address _address = addresses[i];
                uint256 _amount = amounts[i];
                token.transferFrom(msg.sender, _address, _amount);
            }
        }
    }

    function multisendEther(address[] addresses, uint256[] amounts) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < addresses.length; i++) {
            require(total >= amounts[i]);
            total = total.sub(amounts[i]);
            addresses[i].transfer(amounts[i]);
        }
    }
}
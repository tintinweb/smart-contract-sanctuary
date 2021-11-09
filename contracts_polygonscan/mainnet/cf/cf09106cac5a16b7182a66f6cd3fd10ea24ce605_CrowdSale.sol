/**
 *Submitted for verification at polygonscan.com on 2021-11-09
*/

// File: contracts/SafeMath.sol

// SPDX-Licence-Identifier: MIT

pragma solidity ^0.4.23;

//                                )))))))))))))
//                                (((((((((((((
//                                |           |
//                                |( o) (o )  |
//                                \    O      /
//                                 \ (::u::) /
//                                  \_______/

//                          -       .'      \
//                               .-'    | | |
//                              /        \ \ \
//                --        -  |      `---:.`.\
//              ____________._>           \\_\\____ ,--.__
//   --    ,--""           /    `-   .     |)_)    '\     '\
//         /  "             |      .-'     /          \      '\
//       ,/                  \           .'            '\     |
//       | "   "   "          \         /                '\,  /
//       |           " , =_____`-.   .-'_________________,--""
//     - |  "    "    /"/'      /\>-' ( <
//       \  "      ",/ /    -  ( <    |\_)
//        \   ",",_/,-'        |\_)
//     -- -'-;.__:-'

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/ERC20Basic.sol

// SPDX-Licence-Identifier: MIT

pragma solidity ^0.4.23;

//                                )))))))))))))
//                                (((((((((((((
//                                |           |
//                                |( o) (o )  |
//                                \    O      /
//                                 \ (::u::) /
//                                  \_______/

//                          -       .'      \
//                               .-'    | | |
//                              /        \ \ \
//                --        -  |      `---:.`.\
//              ____________._>           \\_\\____ ,--.__
//   --    ,--""           /    `-   .     |)_)    '\     '\
//         /  "             |      .-'     /          \      '\
//       ,/                  \           .'            '\     |
//       | "   "   "          \         /                '\,  /
//       |           " , =_____`-.   .-'_________________,--""
//     - |  "    "    /"/'      /\>-' ( <
//       \  "      ",/ /    -  ( <    |\_)
//        \   ",",_/,-'        |\_)
//     -- -'-;.__:-'

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ERC20.sol

// SPDX-Licence-Identifier: MIT

pragma solidity ^0.4.23;


//                                )))))))))))))
//                                (((((((((((((
//                                |           |
//                                |( o) (o )  |
//                                \    O      /
//                                 \ (::u::) /
//                                  \_______/

//                          -       .'      \
//                               .-'    | | |
//                              /        \ \ \
//                --        -  |      `---:.`.\
//              ____________._>           \\_\\____ ,--.__
//   --    ,--""           /    `-   .     |)_)    '\     '\
//         /  "             |      .-'     /          \      '\
//       ,/                  \           .'            '\     |
//       | "   "   "          \         /                '\,  /
//       |           " , =_____`-.   .-'_________________,--""
//     - |  "    "    /"/'      /\>-' ( <
//       \  "      ",/ /    -  ( <    |\_)
//        \   ",",_/,-'        |\_)
//     -- -'-;.__:-'

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/CrowdSale.sol

// SPDX-Licence-Identifier: MIT

pragma solidity ^0.4.23;



//                                )))))))))))))
//                                (((((((((((((
//                                |           |
//                                |( o) (o )  |
//                                \    O      /
//                                 \ (::u::) /
//                                  \_______/

//                          -       .'      \
//                               .-'    | | |
//                              /        \ \ \
//                --        -  |      `---:.`.\
//              ____________._>           \\_\\____ ,--.__
//   --    ,--""           /    `-   .     |)_)    '\     '\
//         /  "             |      .-'     /          \      '\
//       ,/                  \           .'            '\     |
//       | "   "   "          \         /                '\,  /
//       |           " , =_____`-.   .-'_________________,--""
//     - |  "    "    /"/'      /\>-' ( <
//       \  "      ",/ /    -  ( <    |\_)
//        \   ",",_/,-'        |\_)
//     -- -'-;.__:-'

contract CrowdSale {
    using SafeMath for uint256;
    ERC20 public token;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;

    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token
    ) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        _updatePurchasingState(_beneficiary, weiAmount);
        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        // optional override
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
        internal
    {
        // optional override
    }

    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
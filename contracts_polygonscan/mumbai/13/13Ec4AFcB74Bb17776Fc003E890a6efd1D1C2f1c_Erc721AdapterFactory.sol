pragma solidity ^0.4.24;

import "./Erc721Adapter.sol";

contract Erc721AdapterFactory {

    event NewErc721Adapter(Erc721Adapter erc721Adapter);

    function newErc721Adapter(address _owner) public returns (Erc721Adapter) {
        Erc721Adapter erc721Adapter = new Erc721Adapter(_owner);
        emit NewErc721Adapter(erc721Adapter);
        return erc721Adapter;
    }
}

pragma solidity ^0.4.24;

import "./IConvictionVoting.sol";
import "./IErc721Adapter.sol";
import "./ERC721.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";

// This contract can replace the "stakeToken" in the ConvictionVoting contract. It should be integrated directly into
// an NFT before it's deployment so that it maintains an accurate representation of that NFT.
contract Erc721Adapter is IErc721Adapter {
    using SafeMath for uint256;

    uint256 constant public TOKENS_PER_NFT = 1000e18;

    address public owner;
    IConvictionVoting public convictionVoting;
    ERC721 public erc721;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;

    event SetErc721(address _erc721);

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR:NOT_OWNER");
        _;
    }

    constructor(address _owner) public {
        owner = _owner;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setErc721(ERC721 _erc721) public onlyOwner {
        require(erc721 == address(0), "ERR:ALREADY_SET");

        erc721 = _erc721;
        name = _prependG(_erc721.name());
        symbol = _prependG(_erc721.symbol());

        emit SetErc721(_erc721);
    }

    function setConvictionVoting(IConvictionVoting _convictionVoting) public onlyOwner {
        convictionVoting = _convictionVoting;

        if (address(_convictionVoting) != address(0)) {
            _convictionVoting.onRegisterAsHook(0, address(this));
        }
    }

    // Function used by Conviction Voting
    function totalSupply() view returns (uint256) {
        return totalSupply;
    }

    // Function used by Conviction Voting
    function balanceOf(address _account) view returns (uint256) {
        return balances[_account];
    }

    // In the LivingNft this occurs before the transfer has happened and balanceOf is updated
    // Note this must be called for all mint/burn operations on the NFT as well
    function onTransfer(address _from, address _to, uint256 _id) public {
        require(msg.sender == address(erc721), "ERR:NOT_ERC721");
        require(_from != _to, "ERR:SEND_TO_SELF");

        if (_from != address(0) // not a mint
            && erc721.balanceOf(_from) == 1) // Note balanceOf will be 0 after transfer is completed, this prevents an account with multiple NFT's being revoked vote weight until they have 0 NFT's
        {
            if (address(convictionVoting) != address(0)) {
                convictionVoting.onTransfer(_from, _to, TOKENS_PER_NFT);
            }

            balances[_from] = balances[_from].sub(TOKENS_PER_NFT);
            totalSupply = totalSupply.sub(TOKENS_PER_NFT);
        }

        if (_to != address(0) // not a burn
            && erc721.balanceOf(_to) == 0) // Note balanceOf will be 1 after transfer is completed, this prevents an account with multiple NFT's being granted multiple vote weights
        {
            balances[_to] = balances[_to].add(TOKENS_PER_NFT);
            totalSupply = totalSupply.add(TOKENS_PER_NFT);
        }
    }

    function _prependG(string _string) internal returns (string) {
        return string(abi.encodePacked("g", _string));
    }
}

pragma solidity ^0.4.24;

contract IConvictionVoting {

    function onTransfer(address _from, address _to, uint256 _amount) external returns (bool);

    function onRegisterAsHook(uint256 _hookId, address _token) external;

}

pragma solidity ^0.4.24;

contract IErc721Adapter {

    function onTransfer(address _from, address _to, uint256 _id) public;

}

pragma solidity ^0.4.0;

contract ERC721 {

    function balanceOf(address _owner) public view returns (uint256);

    function name() public view returns (string);

    function symbol() external view returns (string memory);
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}
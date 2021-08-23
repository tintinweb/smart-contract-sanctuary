/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//erc721.sol";
/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function transfer(
    address _to,
    uint256 _tokenId
  )
    external;
    
  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @notice Count all NFTs assigned to an owner.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @notice Find the owner of an NFT.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @notice Query if an address is an authorized operator for another address
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

//erc721-token-receiver.sol";
/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

//erc165.sol";
/**
 * @dev A standard for detecting smart contract interfaces. 
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface ERC165
{

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}

//utils/supports-interface.sol";
/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

//utils/address-utils.sol";
/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

//nf-token.sol
/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
   * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of their tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  function transfer(
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    
    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);
    
    emit Transfer(from, _to, _tokenId);
  }
    
  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn't own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @dev Actually performs the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from which we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  /**
   * @dev Assigns a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to which we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner NFT count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

}

//erc721-metadata.sol
/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Metadata
{

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   * @return _name Representing name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * @return URI of _tokenId.
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  /**
   * @dev A descriptive name for a collection of NFTs.
   */
  string internal nftName;

  /**
   * @dev An abbreviated name for NFTokens.
   */
  string internal nftSymbol;

  /**
   * @dev Mapping from NFT ID to metadata uri.
   */
  mapping (uint256 => string) internal idToUri;

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don't forget to set nftName and nftSymbol.
   */
  constructor()
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   * @return _name Representing name.
   */
  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }

  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    delete idToUri[_tokenId];
  }

  /**
   * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
   * @notice This is an internal function which should be called from user-implemented external
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _tokenId Id for which we want URI.
   * @param _uri String representing RFC 3986 URI.
   */
  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

}

contract LuckyNFT is NFTokenMetadata, Ownable {
  
  ERC721 public nonFungibleContract;
  
  constructor() {
    nftName = "Lucky NFT";
    nftSymbol = "LFT";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external {
    
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    _tokenId++;
  }
//   function _transferNFT(address _from, address _receiver, uint256 _tokenId) public{
//         // it will throw if transfer fails
        
//         emit Transfer(_from, _receiver, _tokenId);
//         //nonFungibleContract.transfer(_receiver, _tokenId);
//     }
}

contract LuckydrawToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _owned;
    mapping (address => mapping (address => uint256)) private _allowances;
    //address payable public  teamDev = payable(0x000000000000000000000000000000000000dead);
    uint256 public lockTime = 730 days;

    string private _name = "Luckydraw NFT";
    string private _symbol = "LKD";
    uint8 private _decimals = 8;
    uint256 private _total = 1000000 *10**uint256(_decimals);

    string public debug = "";

    //A
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    struct BetLucky {
        uint betId;
        address[] addr;
        uint xn;
        uint256 amount;
    }
    BetLucky[] public _betLucky;
    uint8 betCount = 16;
    
    LuckyNFT public _nft;
    struct ListNFT {
        uint256 tokenId;
        uint rare;
    }
    ListNFT[] public _listNFT;
    //address public ownerNFT;
    uint256 private shareFee;
    uint256 private _tokenId = 1;
    uint256 public _betEggsAmount = 10 * 10 ** uint256(_decimals);
    
    uint256 public totalBigLucky = 0;
    uint private n = 1;
    uint256 private win5x = 50* 10 ** uint256(_decimals);
    uint256 private win1xx = 100* 10 ** uint256(_decimals);
    uint256 private win5xx = 500* 10 ** uint256(_decimals);
    uint256 private win1xxx = 1000* 10 ** uint256(_decimals);
    uint256 private win5xxx = 5000* 10 ** uint256(_decimals);
    uint256 private win10xxx = 10000* 10 ** uint256(_decimals);
    uint256 private win50xxx = 50000* 10 ** uint256(_decimals);
    uint256 private win100xxx = 100000* 10 ** uint256(_decimals);
    
    bool private reward5x = false;
    bool private reward1xx = false;
    bool private reward5xx = false;
    bool private reward1xxx = false;
    bool private reward5xxx = false;
    bool private reward10xxx = false;
    bool private reward50xxx = false;
    bool private reward100xxx = false;
    
    uint private count5x = 0;
    uint private count1xx = 0;
    uint private count5xx = 0;
    uint private count1xxx = 0;
    uint private count5xxx = 0;
    uint private count10xxx = 0;
    uint private count50xxx = 0;
    uint private count100xxx = 0;
    
    uint private rd5x;
    uint private rd1xx;
    uint private rd5xx;
    uint private rd1xxx;
    uint private rd5xxx;
    uint private rd10xxx;
    uint private rd50xxx;
    uint private rd100xxx;
    
    struct NFTMarket {
        address ownerAddress;
        uint256 tokenId;
        uint256 price;
    }
    NFTMarket[] public _nftMarketplace;
    
    constructor (LuckyNFT nft) {
        _nft = nft;
        _owned[_msgSender()] = _total/100*85;

        //_owned[teamDev] = _total/100*15;
        lockTime += block.timestamp;
        
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());
        
        // uniswapV2Router = _uniswapV2Router;
        
        emit Transfer(address(0), _msgSender(), _total/100*85);
        //emit Transfer(address(0), teamDev, _total/100*15);
        address[] memory emptyArray;
        _betLucky.push(BetLucky({betId:0, addr:emptyArray, xn: 3, amount: 1 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:1, addr:emptyArray, xn: 3, amount: 5 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:2, addr:emptyArray, xn: 3, amount:10 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:3, addr:emptyArray, xn: 3, amount:50 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:4, addr:emptyArray, xn: 5, amount: 1 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:5, addr:emptyArray, xn: 5, amount: 5 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:6, addr:emptyArray, xn: 5, amount:10 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:7, addr:emptyArray, xn: 5, amount:50 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:8, addr:emptyArray, xn: 10, amount: 1 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:9, addr:emptyArray, xn: 10, amount: 5 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:10, addr:emptyArray, xn: 10, amount:10 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:11, addr:emptyArray, xn: 10, amount:50 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:12, addr:emptyArray, xn: 50, amount: 1 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:13, addr:emptyArray, xn: 50, amount: 5 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:14, addr:emptyArray, xn: 50, amount:10 * 10 ** uint256(_decimals) }));
        _betLucky.push(BetLucky({betId:15, addr:emptyArray, xn: 50, amount:50 * 10 ** uint256(_decimals) }));
        
        rd5x = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
        rd1xx = uint(keccak256(abi.encodePacked(block.timestamp+1, msg.sender, n))) %20;
        rd5xx = uint(keccak256(abi.encodePacked(block.timestamp+2, msg.sender, n))) %20;
        rd1xxx = uint(keccak256(abi.encodePacked(block.timestamp+3, msg.sender, n))) %20;
        rd5xxx = uint(keccak256(abi.encodePacked(block.timestamp+4, msg.sender, n))) %20;
        rd10xxx = uint(keccak256(abi.encodePacked(block.timestamp+5, msg.sender, n))) %20;
        rd50xxx = uint(keccak256(abi.encodePacked(block.timestamp+6, msg.sender, n))) %20;
        rd100xxx = uint(keccak256(abi.encodePacked(block.timestamp+7, msg.sender, n))) %20;
    }
    //y
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _owned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        //if(sender == teamDev){require(block.timestamp > lockTime, "Lock time 2 years");}
        if(sender == owner()){
            _owned[sender] = _owned[sender].sub(amount);
            _owned[recipient] = _owned[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        else
        {
            _owned[sender] = _owned[sender].sub(amount);
            _owned[recipient] = _owned[recipient].add(amount/100*98);
            if(_listNFT.length > 0){
                shareFee = amount/100*2/_listNFT.length;
                address ownerNFT;
                uint rare1=0;
                uint rare2=0;
                uint rare3=0;
                uint rare4=0;
                uint rare5=0;
                uint rareMax=0;
    
                for(uint i=0; i < _listNFT.length; i ++){
                    if(_listNFT[i].rare > rareMax) rareMax = _listNFT[i].rare;
                    if(_listNFT[i].rare == 1) rare1 ++;
                    else if(_listNFT[i].rare == 2) rare2 ++;
                    else if(_listNFT[i].rare == 3) rare3 ++;
                    else if(_listNFT[i].rare == 4) rare4 ++;
                    else if(_listNFT[i].rare == 5) rare5 ++;
                }
                for(uint i=0; i < _listNFT.length; i ++){
                    ownerNFT = _nft.ownerOf(_listNFT[i].tokenId);
                    uint leftShare=0;
                    uint256 amountSend = 0;
    
                    for(uint j=1; j < _listNFT[i].rare; j ++){
                        if(_listNFT[i].rare==1) break;
                        if(j == 1){ leftShare = shareFee/2*rare1; }
                        else if(j == 2){ leftShare = (shareFee*rare2 + leftShare)/2; }
                        else if(j == 3){ leftShare = (shareFee*rare3 + leftShare)/2; }
                        else if(j == 4){ leftShare = (shareFee*rare4 + leftShare)/2; }
                    }
                    if(_listNFT[i].rare == 1){
                        amountSend = shareFee/2;
                    }
                    else if(_listNFT[i].rare == 2){
                        amountSend = (shareFee*rare2 + leftShare)/2 /rare2;
                    }
                    else if(_listNFT[i].rare == 3){
                        amountSend = (shareFee*rare3 + leftShare)/2 /rare3;
                    }
                    else if(_listNFT[i].rare == 4){
                        amountSend = (shareFee*rare4 + leftShare)/2 /rare4;
                    }
                    else if(_listNFT[i].rare == 5){
                        amountSend = (shareFee*rare5 + leftShare)/2 /rare5;
                    }
                    _owned[ownerNFT] = _owned[ownerNFT].add(amountSend);
                    emit Transfer(sender, ownerNFT, amountSend);
                }
            }
            else{
                _owned[owner()] = _owned[owner()].add(amount/100*2);
                emit Transfer(sender, owner(), amount/100*2);
            }
            emit Transfer(sender, recipient, amount/100*98);
         }
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //M
    function createBetLucky(uint256 _amount,uint _xn) public onlyOwner(){
        address[] memory emptyArray;
        _betLucky.push(BetLucky({betId:betCount, addr:emptyArray, xn: _xn, amount:_amount}));
        betCount++;
    }

    //E
    function betLuckyDraw(uint betId) public returns (bool){
        address winners;
        BetLucky storage chooseBet = _betLucky[betId];//choose game
        uint256 tokens = chooseBet.amount;//get amout token of game

        transfer(owner(), tokens);

        chooseBet.addr.push(_msgSender());
        if(chooseBet.addr.length == chooseBet.xn){
            // generate random# from block number 
            uint randomIndex = (block.number / chooseBet.addr.length) % chooseBet.addr.length; 

            // winner
            winners = chooseBet.addr[randomIndex];

            //transfer to winner
            _transfer(owner(), winners, tokens*chooseBet.xn/100*95);

            //end
            address[] memory emptyArray;
            chooseBet.addr = emptyArray;
        }
        return true;
    }
    //N
    function getBetLucky(uint betId) public view returns (BetLucky memory) {
        BetLucky storage bet = _betLucky[betId];
    
        return bet;
    }
    
    function betEggsGame(uint256 betEggs) public onlyOwner(){
        _betEggsAmount = betEggs;
    }
    
    function eggs() public returns (uint256){
        count5x++;
        transfer(owner(), _betEggsAmount);
        
        //count
        if(count5x==20){
            count5x = 0;
            rd5x = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count1xx++;
        }
        if(count1xx==20){
            count1xx = 0;
            rd1xx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count5xx++;
        }
        if(count5xx==20){
            count5xx = 0;
            rd5xx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count1xxx++;
        }
        if(count1xxx==20){
            count1xxx = 0;
            rd1xxx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count5xxx++;
        }
        if(count5xxx==20){
            count5xxx = 0;
            rd5xxx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count10xxx++;
        }
        if(count10xxx==20){
            count10xxx = 0;
            rd10xxx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count50xxx++;
        }
        if(count50xxx==20){
            count50xxx = 0;
            rd50xxx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            count100xxx++;
        }

        //count with rd
        if(count5x == rd5x) reward5x = true;
        if(count1xx == rd1xx) reward1xx = true;
        if(count5xx == rd5xx) reward5xx = true;
        if(count1xxx == rd1xxx) reward1xxx = true;
        if(count5xxx == rd5xxx) reward5xxx = true;
        if(count10xxx == rd10xxx) reward10xxx = true;
        if(count50xxx == rd50xxx) reward50xxx = true;
        if(count100xxx == rd100xxx) reward100xxx = true;
        
        //reward
        if(reward100xxx){
            _transfer(owner(), _msgSender(), win100xxx);
            count100xxx = 0;
            rd100xxx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %20;
            reward100xxx = false;
            return win100xxx;
        }else if(reward50xxx){
            _transfer(owner(), _msgSender(), win50xxx);
            reward50xxx = false;
            return win50xxx;
        }else if(reward10xxx){
            _transfer(owner(), _msgSender(), win10xxx);
            reward10xxx = false;
            return win10xxx;
        }else if(reward5xxx){
            _transfer(owner(), _msgSender(), win5xxx);
            reward5xxx = false;
            return win5xxx;
        }else if(reward1xxx){
            _transfer(owner(), _msgSender(), win1xxx);
            reward1xxx = false;
            return win1xxx;
        }else if(reward5xx){
            _transfer(owner(), _msgSender(), win5xx);
            reward5xx = false;
            return win5xx;
        }else if(reward1xx){
            _transfer(owner(), _msgSender(), win1xx);
            reward1xx = false;
            return win1xx;
        }else if(reward5x){
            _transfer(owner(), _msgSender(), win5x);
            reward5x = false;
            return win5x;
        }
        else{

            uint rd = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %1000;
            if(rd == 1){// 0.1 1 5 10 20
                _listNFT.push(ListNFT({tokenId:_tokenId, rare:5}));
                _nft.mint(_msgSender(), _tokenId, 'https://ipfs.io/ipfs/QmYv1andXVDuUkccWa4abrrxv4MBYeGUiik1QkJC7mCA12');
                _tokenId++;
                return _tokenId-1;
            }
            else if(rd < 11){
                _listNFT.push(ListNFT({tokenId:_tokenId, rare:4}));
                _nft.mint(_msgSender(), _tokenId, 'https://ipfs.io/ipfs/QmYwGHRYDiFvMhqdQnVLBGxtBU9EAE5VitbQLX9JJce9TT');
                _tokenId++;
                return _tokenId-1;
            }
            else if(rd < 51){
                _listNFT.push(ListNFT({tokenId:_tokenId, rare:3}));
                _nft.mint(_msgSender(), _tokenId, 'https://ipfs.io/ipfs/QmWYvZRqtxRgjExx53MwTAr2tvjjPAbyyNn7vSVWsQZU7T');
                _tokenId++;
                return _tokenId-1;
            }
            else if(rd < 101){
                _listNFT.push(ListNFT({tokenId:_tokenId, rare:2}));
                _nft.mint(_msgSender(), _tokenId, 'https://ipfs.io/ipfs/QmZeLLcwjHmbwVwwBVtfUsWWXnwVBEqsXkVvysMR11sAdw');
                _tokenId++;
                return _tokenId-1;
            }
            else if(rd < 201){
                _listNFT.push(ListNFT({tokenId:_tokenId, rare:1}));
                uint rdindex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, n))) %12;
                string[12] memory zodiacs = [
                    'https://ipfs.io/ipfs/QmQnRDETZUShYfqEjvMwRq4fqJdD43hBV9hVRgqznBCUCK',
                    'https://ipfs.io/ipfs/QmVevwsjdF7pS27gWLtzpShcP6HuDtFWZFKQLYumN5eqkk',
                    'https://ipfs.io/ipfs/QmPZiLkjFKFvFLgR75nC7WGC23bv8jqVvADa8ChKertuPC',
                    'https://ipfs.io/ipfs/QmNgdK8KkSiHW311Rj8ixmpZgjHsU3EeiaVMe56FZDvEav',
                    'https://ipfs.io/ipfs/QmUEXiutmJ7FxUZ38ycpSSK2n3gFTpmWdsj2UQwFwYpAH9',
                    'https://ipfs.io/ipfs/QmfJRNG2PQzNRrV3u1L2HDZTZ1YoNTvkNED4W4GrBiBgSn',
                    'https://ipfs.io/ipfs/QmSrTCSPbTqm5x1MA2HkqKNsEk6JyzVR2NVJwG7rgvv7tB',
                    'https://ipfs.io/ipfs/QmZEuysXQTM8FPmxWebc9bSRfgquFnjvKCRhCsu56wJKDM',
                    'https://ipfs.io/ipfs/QmaCKqkBQrmGStvLr4re9Je2dZ8b6JD6sUTSww7pr2RLD5',
                    'https://ipfs.io/ipfs/QmeuYnx4CRZsCZx6rD5JprRjH3LDFPcshBtci8Z7TUZZUh',
                    'https://ipfs.io/ipfs/QmPoutrBLHzMuRhaXDvh69nz16K9tF9RfGfSjkHTQbtmkN',
                    'https://ipfs.io/ipfs/QmNd4iFFNBpDBSnw1843zG3qR3TrpmG1yqVE5A4sjyrpMJ'
                    ];
                _nft.mint(_msgSender(), _tokenId, zodiacs[rdindex]);
                _tokenId++;
                return _tokenId-1;
            }
        }
        return 0;
    }
    
    function sellMarket(uint256 tokenId, uint256 price) public returns (bool){
        require(tokenId != 0, "NFT not zero");
        require(price > 0, "price must be greater than zero");
        address ownerNFT = _nft.ownerOf(tokenId);
        if(ownerNFT == _msgSender()){
            for(uint i=0; i<_nftMarketplace.length; i++){
                if(_nftMarketplace[i].tokenId == tokenId){
                    return false;
                }
            }
            _nftMarketplace.push(NFTMarket({ownerAddress: _msgSender(), tokenId: tokenId, price: price }));
            return true;
        }
        return false;
    }
    
    function cancelMarket(uint256 tokenId) public returns (bool){
        require(tokenId != 0, "NFT not zero");
        address ownerNFT = _nft.ownerOf(tokenId);
        if(ownerNFT == _msgSender()){
            for(uint i=0; i<_nftMarketplace.length; i++){
                if(_nftMarketplace[i].tokenId == tokenId){
                    delete _nftMarketplace[i];
                    return true;
                }
            }
        }
        return false;
    }
    
    function buyMarket(uint256 tokenId) public returns (bool){
        require(tokenId != 0, "NFT not zero");
        address ownerNFT = _nft.ownerOf(tokenId);
 
        for(uint i=0; i<_nftMarketplace.length; i++){
            if(_nftMarketplace[i].tokenId == tokenId){
                _transfer(_msgSender(), ownerNFT, _nftMarketplace[i].price);
                _nft.transfer(_msgSender(), tokenId);
                return true;
            }
        }

        return false;
    }
}
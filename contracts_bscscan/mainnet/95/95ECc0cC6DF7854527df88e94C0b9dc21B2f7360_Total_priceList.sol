/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity >= 0.5.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface contract_price{
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update_now()external;
}

pragma solidity >= 0.5.0;

//
contract Total_priceList is Ownable{
    mapping(uint=>address) contract_priceList;
    mapping(address=>address) Token_address;
    mapping(uint=>uint) nameList;   //666 usdt
    uint nameLen;
   
   event Addtoken(uint  name,address contract_price,address token);
   event Removetoken(uint name);
   event Fixxaddress(uint name,address addr);
   event Fixxtoken(address contract_,address token);
   event SetNameList(uint[] name);
   
    function add_token(uint  name,address contract_price,address token) public onlyOwner{
        contract_priceList[name] = contract_price;
        Token_address[contract_price] = token;
        
        emit Addtoken(name,contract_price,token);
    }

    function remove_token(uint name) public onlyOwner{
        Token_address[contract_priceList[name]] = address(0);
        contract_priceList[name] = address(0);
        
        emit Removetoken( name);
    }
    function fixxaddress(uint name,address addr) public onlyOwner{
        contract_priceList[name] = addr;
        
        emit Fixxaddress( name, addr);
    }

    function fixx_token(address contract_,address token) public onlyOwner{
        Token_address[contract_] = token;
        
        emit Fixxtoken( contract_, token);
    }

    function setNameList(uint[] memory name)public onlyOwner{
        for(uint i;i<name.length;i++){
            nameList[i] = name[i];
        }
        nameLen = name.length;
        
        emit SetNameList(name);
    }

    function update_() public{
        for(uint i=0;i<nameLen;i++){
            if(nameList[i] != 666)
            contract_price(contract_priceList[nameList[i]]).update_now();
        }
    }
    function getPrice()  public view returns(uint256[] memory ){
        uint256[] memory priceList =  new uint256[](nameLen);
        for(uint i=0;i<nameLen;i++){
            if(nameList[i] != 666)
            {
                priceList[i] = contract_price(contract_priceList[nameList[i]]).consult(Token_address[contract_priceList[nameList[i]]],100);
            }
            
            if(nameList[i] == 666)
            {
                priceList[i]=100;
            }
            
        }
        return priceList;
    }
}
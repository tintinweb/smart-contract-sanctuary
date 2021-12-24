/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

     function _msgValue() internal view returns (uint){
    return msg.value;
     }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract prices is Ownable{

    
    //cofres
    uint private _CommonChest=1;
    uint private _RareChest=2;
    uint private _EpicChest=3;

    //barcos
    uint private constant _ship_1=4;
    uint private constant _ship_2=5;
    uint private constant _ship_3=6;
    uint private constant _ship_4=7;
    uint private constant _ship_5=8;

    //islas
    uint private constant _isla=9;

    //objeros 
    uint private constant _common=10;
    uint private constant _rare=11;
    uint private constant _epic=12;
    uint private constant _mythical=13;
    uint private constant _legendary=14;

    mapping(uint=>uint) private ItemId;

    constructor(){
        //cofres
        ItemId[_CommonChest]= 0.04 ether;
        ItemId[_RareChest]= 0.1 ether;
        ItemId[_EpicChest]= 0.2 ether;

        //barcos
        ItemId[_ship_1]= 0.1 ether;
        ItemId[_ship_2]= 0.2 ether;
        ItemId[_ship_3]= 0.5 ether;
        ItemId[_ship_4]= 0.78 ether;
        ItemId[_ship_5]= 1 ether;

        //islas
        ItemId[_isla]= 1 ether;

        //objetos
        ItemId[_common]= 0.04 ether;
        ItemId[_rare]= 0.08 ether;
        ItemId[_epic]= 0.17 ether;
        ItemId[_mythical]= 0.2 ether;
        ItemId[_legendary]= 0.4 ether;
    }

    function getItemPrecio(uint256 _id) public view returns(uint){
        return ItemId[_id];
    }

    function setItemPreci(uint _id,uint _price)public onlyOwner{
        ItemId[_id]=_price;
    }
}

contract presale is prices {
 
 function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual  returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual  returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }


address private _ItemsNft;

uint private num;

bool private _pause;

constructor() {
    _pause=false;
}

modifier restrictions(){
    require(_pause,"pre-sale paused");
    _;
}

function ramdo(address _to)internal returns(uint){
        num++;
        return uint(keccak256(abi.encode(block.timestamp,_to,num)))%(10**2); 
}

function commonChest()public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(1),"monto incorrecto");
    commonChestChance(_msgSender(),ramdo(_msgSender()));
    return true;
}

function commonChestChance(address _to,uint _a) internal {

        if(_a>=0 && _a<=44){
            if(getBalanceNFT(1)>=1){
            _TransferNFT(_to,1,1);
            }else{
              estructura(_to);
         }
        }else if(_a>=45 && _a<=79){

        if(getBalanceNFT(2)>=1){
            _TransferNFT(_to,2,1);
        }else{
           estructura(_to);
        }
        }else if(_a>=80 && _a<=94){
        if(getBalanceNFT(3)>=1){
            _TransferNFT(_to,3,1);
        }else{
           estructura(_to);
        }
        }else if(_a>=95 && _a<=98){
        if(getBalanceNFT(4)>=1){
            _TransferNFT(_to,4,1);
        }else{
           estructura(_to);
        }
        }else if(_a==99){
        if(getBalanceNFT(5)>=1){
            _TransferNFT(_to,5,1);
        }else{
           estructura(_to);
        }
        }else{
        revert("error, random number not supported");
        }

}

function careChest()public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(2),"monto incorrecto");
    careChestChance(_msgSender(),ramdo(_msgSender()));
    return true;
}

function careChestChance(address _to,uint _a) internal {

    if(_a>=0 && _a<=19){
        if(getBalanceNFT(1)>=1){
            _TransferNFT(_to,1,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=20 && _a<=63){

        if(getBalanceNFT(2)>=1){
            _TransferNFT(_to,2,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=64 && _a<=88){
        if(getBalanceNFT(3)>=1){
            _TransferNFT(_to,3,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=89 && _a<=96){
        if(getBalanceNFT(4)>=1){
            _TransferNFT(_to,4,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=97 && _a<=99){
        if(getBalanceNFT(5)>=1){
            _TransferNFT(_to,5,1);
        }else{
           estructura(_to);
        }
    }else{
        revert("error, random number not supported");
    }

}

function epicChest()public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(3),"monto incorrecto");
    epicChestChance(_msgSender(),ramdo(_msgSender()));
    return true;
}

function epicChestChance(address _to,uint _a) internal {

    if(_a>=94 && _a<=99){
        if(getBalanceNFT(1)>=1){
            _TransferNFT(_to,1,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=89 && _a<=93){

        if(getBalanceNFT(2)>=1){
            _TransferNFT(_to,2,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=74 && _a<=88){
        if(getBalanceNFT(3)>=1){
            _TransferNFT(_to,3,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=0 && _a<=40){
        if(getBalanceNFT(4)>=1){
            _TransferNFT(_to,4,1);
        }else{
           estructura(_to);
        }
    }else if(_a>=41 && _a<=73){
        if(getBalanceNFT(5)>=1){
            _TransferNFT(_to,5,1);
        }else{
           estructura(_to);
        }
    }else{
        revert("error, random number not supported");
    }

}

function ship_1() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(4),"monto incorrecto");
    require(getBalanceNFT(6)>0,"item not available");
    _TransferNFT(_msgSender(),6,1);
    return true;
}
function ship_2() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(5),"monto incorrecto");
    require(getBalanceNFT(7)>0,"item not available");
    _TransferNFT(_msgSender(),7,1);
    return true;
}
function ship_3() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(6),"monto incorrecto");
    require(getBalanceNFT(8)>0,"item not available");
    _TransferNFT(_msgSender(),8,1);
    return true;
}
function ship_4() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(7),"monto incorrecto");
    require(getBalanceNFT(9)>0,"item not available");
    _TransferNFT(_msgSender(),9,1);
    return true;
}
function ship_5() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(8),"monto incorrecto");
    require(getBalanceNFT(10)>0,"item not available");
    _TransferNFT(_msgSender(),10,1);
    return true;
}

function islandChest()public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(9),"monto incorrecto");
    islandChestChance(_msgSender(),ramdo(_msgSender()));
    return true;
}
function islandChestChance(address _to,uint _a) internal {

        if(_a>=0 && _a<=40){
            if(getBalanceNFT(1)>=1){
            _TransferNFT(_to,11,1);
            }else{
              islandEstructura(_to);
         }
        }else if(_a>=41 && _a<=70){

        if(getBalanceNFT(2)>=1){
            _TransferNFT(_to,12,1);
        }else{
           islandEstructura(_to);
        }
        }else if(_a>=71 && _a<=90){
        if(getBalanceNFT(3)>=1){
            _TransferNFT(_to,13,1);
        }else{
           islandEstructura(_to);
        }
        }else if(_a>=91 && _a<=99){
            if(getBalanceNFT(4)>=1){
                _TransferNFT(_to,14,1);
            }else{
                estructura(_to);
            }
        }else{
        revert("error, random number not supported");
        }

}

function commonSword() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(10),"monto incorrecto");
    require(getBalanceNFT(15)>0,"item not available");
    _TransferNFT(_msgSender(),15,1);
    return true;
}
function commonShovel() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(10),"monto incorrecto");
    require(getBalanceNFT(19)>0,"item not available");
    _TransferNFT(_msgSender(),19,1);
    return true;
}
function commonBlunderbuss() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(10),"monto incorrecto");
    require(getBalanceNFT(23)>0,"item not available");
    _TransferNFT(_msgSender(),23,1);
    return true;
}

function rareSword() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(11),"monto incorrecto");
    require(getBalanceNFT(16)>0,"item not available");
    _TransferNFT(_msgSender(),16,1);
    return true;
}
function rareShovel() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(11),"monto incorrecto");
    require(getBalanceNFT(20)>0,"item not available");
    _TransferNFT(_msgSender(),20,1);
    return true;
}
function rareBlunderbuss() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(11),"monto incorrecto");
    require(getBalanceNFT(24)>0,"item not available");
    _TransferNFT(_msgSender(),24,1);
    return true;
}

function epicSword() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(12),"monto incorrecto");
    require(getBalanceNFT(17)>0,"item not available");
    _TransferNFT(_msgSender(),17,1);
    return true;
}

function epicShovel() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(12),"monto incorrecto");
    require(getBalanceNFT(21)>0,"item not available");
    _TransferNFT(_msgSender(),21,1);
    return true;
}
function epicBlunderbuss() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(12),"monto incorrecto");
    require(getBalanceNFT(25)>0,"item not available");
    _TransferNFT(_msgSender(),25,1);
    return true;
}


function mythicalSword() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(13),"monto incorrecto");
    require(getBalanceNFT(18)>0,"item not available");
    _TransferNFT(_msgSender(),18,1);
    return true;
}
function mythicalShovel() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(13),"monto incorrecto");
    require(getBalanceNFT(22)>0,"item not available");
    _TransferNFT(_msgSender(),22,1);
    return true;
}
function mythicalBlunderbuss() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(13),"monto incorrecto");
    require(getBalanceNFT(26)>0,"item not available");
    _TransferNFT(_msgSender(),26,1);
    return true;
}

function legendaryOutfit() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(14),"monto incorrecto");
    require(getBalanceNFT(27)>0,"item not available");
    _TransferNFT(_msgSender(),27,1);
    return true;
}
function legendaryRifle() public payable restrictions returns(bool){
    require(_msgValue()==prices.getItemPrecio(14),"monto incorrecto");
    require(getBalanceNFT(28)>0,"item not available");
    _TransferNFT(_msgSender(),28,1);
    return true;
}

function estructura(address _to) internal{
    if(getBalanceNFT(1)>=1){
        _TransferNFT(_to,1,1);
    }else if(getBalanceNFT(2)>=1){
        _TransferNFT(_to,2,1);
    }else if(getBalanceNFT(3)>=1){
        _TransferNFT(_to,3,1);
    }else if(getBalanceNFT(4)>=1){
        _TransferNFT(_to,4,1);
    }else if(getBalanceNFT(5)>=1){
        _TransferNFT(_to,5,1);
    }else{
        revert("no NFT available");
    }
}

function islandEstructura(address _to) internal{
    if(getBalanceNFT(1)>=1){
        _TransferNFT(_to,11,1);
    }else if(getBalanceNFT(2)>=1){
        _TransferNFT(_to,12,1);
    }else if(getBalanceNFT(3)>=1){
        _TransferNFT(_to,13,1);
    }else if(getBalanceNFT(4)>=1){
        _TransferNFT(_to,14,1);
    }else{
        revert("no NFT available");
    }
}
function sendToOwner() public onlyOwner returns(bool){
    require(address(this).balance>0);
    _sendValue(payable(owner()),address(this).balance);
    return true;
}

function withdrawals(address _buyer,uint mount) public onlyOwner returns(bool){
    require(address(this).balance>=0);
    _sendValue(payable(_buyer),mount);
    return true;
}

function getBalanceContract()public view returns(uint){
return address(this).balance;
}

function getBalanceNFT(uint _id)internal returns(uint){

  (bool success, bytes memory data) = _ItemsNft.call(abi.encodeWithSignature(
    "balanceOf(address,uint256)",address(this),_id));
    require(success,"no se pudo obtener el balance");
    (uint a) = abi.decode(data, (uint));
    return a;

}


function setItemsNftAddress(address NewAddress) public onlyOwner(){
    _ItemsNft = NewAddress;
}


function pause() public onlyOwner {
    require(_pause != false);
    _pause = !_pause;
}


function onPause()public onlyOwner{
    require(_pause != true);
    _pause = !_pause;
}

function _TransferNFT(address _to,uint _id,uint _amount)internal{

  (bool success, ) = _ItemsNft.call(abi.encodeWithSignature(
    "safeTransferFrom(address,address,uint256,uint256,bytes)",address(this),_to,_id,_amount,"[]"));

    require(success,"no se pudo realizar la transferencia");

}


function _sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
}

}
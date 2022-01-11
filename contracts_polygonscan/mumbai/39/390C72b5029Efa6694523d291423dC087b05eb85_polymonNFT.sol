/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface INFT{
    function mint(address account, uint256 id, uint256 amount, bytes memory data, string memory newuri) external;
}

contract polymonNFT is Ownable {

    uint256[3] public price;
    INFT public customNFTAddress;
    INFT public rareNFTAddress;
    INFT public legendaryNFTAddress;
    address public signerAddress;

    event buyEvent(address indexed _buyer, uint256 _tokenID, uint256 _type);

    constructor(INFT _customNFTAddress,INFT _rareNFTAddress,INFT _legendaryNFTAddress,address _signerAddress){
        customNFTAddress = _customNFTAddress;
        rareNFTAddress = _rareNFTAddress;
        legendaryNFTAddress = _legendaryNFTAddress;
        signerAddress = _signerAddress;
    }

    receive() external payable{}

    function setPrice(uint256[3] memory _price)public onlyOwner{
        price[0] = _price[0]; // Custom NFT
        price[1] = _price[1]; // Rare NFT
        price[2] = _price[2]; // Legendary NFT
    }

    function setSignerAddress(address _signer)public onlyOwner{
        signerAddress = _signer;
    }

   struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    function buy(uint _type,address to,uint _id,uint _amount,bytes memory _data,string memory _newuri,Sig memory sig)external payable{
        require(_type == 1 || _type == 2 || _type == 3 ,"Invalid Type");
        validateSignature(_type,_msgSender(),_id,_amount,_data,_newuri,sig);
        if(_type == 1){ // Custom NFT
            require(price[0] == msg.value && price[0] > 0 ,"Invalid Custom Price");
            INFT(customNFTAddress).mint(to,_id,_amount,_data,_newuri);
        }
        else if(_type == 2){ // Rare NFT
            require(price[1] == msg.value && price[1] > 0 ,"Invalid Rare Price");
            INFT(rareNFTAddress).mint(to,_id,_amount,_data,_newuri);
        }
        else if(_type == 3){ // Legendary NFT
            require(price[2] == msg.value && price[2] > 0 ,"Invalid Legendary Price");
            INFT(legendaryNFTAddress).mint(to,_id,_amount,_data,_newuri);
        }

        emit buyEvent(to,_id,_type);

    }


    function validateSignature(uint _type,address _to,uint _id,uint _amount,bytes memory _data,string memory _newuri, Sig memory sig) public {
         bytes32 hash = prepareHash(_type, _to, _id, _amount, _data, _newuri);
         require(ecrecover(hash, sig.v, sig.r, sig.s) == signerAddress , "Invalid Signature");
    }

    function prepareHash(uint _type,address _to,uint _id,uint _amount,bytes memory _data,string memory _newuri)public  pure returns(bytes32){
        bytes32 hash = keccak256(abi.encodePacked(_type,_to,_id,_amount,_data,_newuri));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}
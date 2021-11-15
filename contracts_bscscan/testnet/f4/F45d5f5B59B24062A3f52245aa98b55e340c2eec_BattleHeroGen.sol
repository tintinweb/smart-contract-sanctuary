// SPDX-License-Identifier: MIT
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
contract BattleHeroFactory{
    function mint(address to, bytes32 genes) public virtual {}
    function balanceOf(address owner) public view virtual returns (uint256) {}
}
contract BattleHero{
    function transferFrom(address from, address buyer, uint256 numTokens) public returns (bool) {}
    function balanceOf(address tokenOwner) public view returns (uint256) {}
}
contract BattleHeroGen is Ownable {
    BattleHeroFactory _bhf;
    BattleHero _bh;
    struct Breed{
        uint blockBreed;
        uint when;
    }
    mapping(address => Breed) _breeds;
    constructor() {
        setFactoryContract(0x3FC920EdD02f71A69BaECE9a9e9c4683a22f2f3D);
        setTokenContract(0x343e1cC386F39beF89F8e05e97a3e5a61cB1498a);        
    }
   
    function setFactoryContract(address factoryContract) public onlyOwner { 
        _bhf = BattleHeroFactory(factoryContract);
        
    }
    function setTokenContract(address tokenContract) public onlyOwner{
        _bh = BattleHero(tokenContract);
    }

    function tokenBalance(address ownerToken) public view  returns(uint256){
        return _bhf.balanceOf(ownerToken);
    }
    
    function generate() public{
        _breeds[msg.sender] = Breed(block.number + 2, block.timestamp);
    }

    function claim() public {
        Breed memory currentBreed = _breeds[msg.sender];
        require(currentBreed.blockBreed < block.number);
        bytes32 gen = keccak256(abi.encodePacked(blockhash(currentBreed.blockBreed), blockhash(block.number)));
        _bhf.mint(msg.sender, gen);
    }

    


    
}


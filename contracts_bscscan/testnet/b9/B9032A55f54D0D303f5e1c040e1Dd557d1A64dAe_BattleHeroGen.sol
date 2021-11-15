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
    function mint(address to, uint256 genes) public virtual {}
    function balanceOf(address owner) public view virtual returns (uint256) {}
}
contract BattleHero{
    function transferFrom(address from, address buyer, uint256 numTokens) public returns (bool) {}
    function balanceOf(address tokenOwner) public view returns (uint256) {}
}
contract BattleHeroGen is Ownable {
    BattleHeroFactory _bhf;
    BattleHero _bh;

    constructor() {
        setFactoryContract(0x18c7FbC72787769C074dcC40F95B043D31717B2c);
        setTokenContract(0x343e1cC386F39beF89F8e05e97a3e5a61cB1498a);        
    }
    function _genes(address sender, uint256 seed) internal view returns(uint256) {
        uint256 gen = uint256(keccak256(abi.encodePacked(uint256(uint256(uint160(sender)) + seed + uint256(blockhash(block.number - 1))))));
        return gen;
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

    function generate() public {
        // require(_bh.balanceOf(msg.sender) > 1);
        uint256 genes = _genes(msg.sender, uint256(blockhash(block.number - 5)));
        _bhf.mint(msg.sender, genes);
    }
}


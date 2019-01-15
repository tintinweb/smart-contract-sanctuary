pragma solidity 0.4.24;

contract Delegate {

    function mint(address _sender, address _to) public returns (bool);

    function approve(address _sender, address _to, uint256 _tokenId) public returns (bool);

    function setApprovalForAll(address _sender, address _operator, bool _approved) public returns (bool);

    function transferFrom(address _sender, address _from, address _to, uint256 _tokenId) public returns (bool);
    
    function safeTransferFrom(address _sender, address _from, address _to, uint256 _tokenId) public returns (bool);

    function safeTransferFrom(address _sender, address _from, address _to, uint256 _tokenId, bytes memory _data) public returns (bool);

}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}


contract BasicMintable is Delegate, Ownable {

    mapping(address => bool) public minters;

    function setCanMint(address minter, bool canMint) public onlyOwner {
        minters[minter] = canMint;
    }

    bool public canAnyMint = true;

    function setCanAnyMint(bool canMint) public onlyOwner {
        canAnyMint = canMint;
    }

    function mint(address _sender, address) public returns (bool) {
        require(canAnyMint, "no minting possible");
        return minters[_sender];
    }

    function approve(address, address, uint256) public returns (bool) {
        return true;
    }

    function setApprovalForAll(address, address, bool) public returns (bool) {
        return true;
    }

    function transferFrom(address, address, address, uint256) public returns (bool) {
        return true;
    }
    
    function safeTransferFrom(address, address, address, uint256) public returns (bool) {
        return true;
    }

    function safeTransferFrom(address, address, address, uint256, bytes memory) public returns (bool) {
        return true;
    }

}
pragma solidity ^0.8.0;

// BaseURI:
// https://www.citadelofthemachines.com/token/

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract CitadelOfTheMachines is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 200;
    uint256 private _price = 0.045 ether;
    uint256 private _machinatorPrice = 0.00 ether;
    uint256 public _machinatorStartCount = 10000;
    bool public _paused = true;
    bool public _machinatorPaused = true;
    mapping(uint256 => bool) private unboxedMachine;

    // withdraw addresses
    //xz
    address machines = 0xBEBFf53bB6796d21033f38a46808B47E90777345;
    address machinator = 0x1E2fe8DC9e0605AE167Bdf69EEADbA459B076241;
    address machineer = 0x1Da6Cf54Ef6F057D86ad1898f7C531c654052C22;

    // 9999 Machines in total
    constructor(string memory baseURI) ERC721("Citadel of the Machines", "COTM")  {
        setBaseURI(baseURI);

        // team gets the first 3 machines
        _safeMint( machines, 0);
        _safeMint( machinator, 1);
        _safeMint( machineer, 2);

    }

    function purchase(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can purchase a maximum of 20 Machines" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum Machines supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function setMachinatorPrice(uint256 _newPrice) public onlyOwner() {
        _machinatorPrice = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function getMachinatorPrice() public view returns (uint256){
        return _machinatorPrice;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Machines supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function unboxMachine(uint256 tokenId, bool val) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Machine does not belong to you.");
        unboxedMachine[tokenId] = val;
    }

    function isUnboxed(uint id) public view returns(bool) {
        return unboxedMachine[id];
    }


    function _machinateProcess() private  {
        require( _machinatorStartCount + 1 < 15000,         "Exceeds maximum Machines that can be created" );
        require( msg.value >= _machinatorPrice,             "Ether sent is not correct" );
        _safeMint( msg.sender, _machinatorStartCount + 1 );
        _machinatorStartCount = _machinatorStartCount+1;
    }

    function sendMachinator(uint256 machine1, uint256 machine2) public {
        require( !_machinatorPaused,                  "Machinator is offline" );
        require(_exists(machine1),                    "sendMachinator: Machine 1 does not exist.");
        require(_exists(machine2),                    "sendMachinator: Machine 2 does not exist.");
        require(ownerOf(machine1) == _msgSender(),    "sendMachinator: Machine 1 caller is not token owner.");
        require(ownerOf(machine2) == _msgSender(),    "sendMachinator: Machine 2 caller is not token owner.");
        require( machine1 <=  10000,             "Machine 1 is not a genesis Machine" );
        require( machine2 <=  10000,             "Machine 2 is not a genesis Machine" );
        require( unboxedMachine[machine1],              "Machine 1 is not unboxed" );
        require( unboxedMachine[machine2],              "Machine 2 is not unboxed" );

        require(machine1 != machine2, "Both Machines can't be the same ");
        _burn(machine1);
        _burn(machine2);
        _machinateProcess();
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function machinatorPause(bool val) public onlyOwner {
        _machinatorPaused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 2;
        require(payable(machines).send(_each));
        require(payable(machinator).send(_each));
    }
}
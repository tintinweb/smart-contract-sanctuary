// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
interface OldContract {
    function viewWhitelistOneStatus(address _user) external view returns(bool);
    function totalAvailableForUser(address _user) external view returns(uint);
    //WHITELISTS
    function whiteListOne(uint) external view returns (address);
    function whiteListTwo(uint) external view returns (address);
    function whiteListThree(uint) external view returns (address);
    function whiteListFour(uint) external view returns (address);
    function whiteListFive(uint) external view returns (address);
    function whiteListSix(uint) external view returns (address);
    function whiteListSeven(uint) external view returns (address);
    function whiteListEight(uint) external view returns (address);
    function whiteListNine(uint) external view returns (address);
    function whiteListTen(uint) external view returns (address);
    function whiteListEleven(uint) external view returns (address);
    //CURRENT OWNERS OF COVIES
    function totalSupply() external view returns(uint);
    function ownerOf(uint) external view returns(address);
    function balanceOf(address) external view returns(uint);
}

contract CoviesDegens is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxCoviesSupply = 2019;

    bool public claimableSale = false;
    bool public regularSale = false;

    bool private revealed = false;

    address[] private _team = [
        0x700eec4D6Ed56ED0F97a0f43Fc9DF5B426Ba25Fc,
        0xDFf1889Ec0F09d14dE9379938bDc3Df0c6D0B39C, // TODO: Replace by Kickbeat address
        0x4c2a5a4ea0d3f7E9142535f260A05b975Ee1df02 // TODO: Replace by Jacobb address
        ];

    uint256[] private _teamShares = [
        33,
        33,
        33
        ];

    uint public mintPrice;
    // OldContract private oldContract;

    mapping (uint256 => string) private _tokenURIs;
    string public baseURI;

    mapping(address => uint256) public totalClaimable;
    mapping(address => uint256) public totalClaimed;
    address[] public claimers;

    // uint private iOwner = 1;
    uint public maxPerTransaction = 5;

    constructor() ERC721("2k19 Covies Degen's", "COVIES") PaymentSplitter(_team, _teamShares) {
        //SET MINT PRICE
        mintPrice = 80000000000000000;
        //GET OLD CONTRACT
        // oldContract = OldContract(_oldContract);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        if(!revealed){
            return bytes(base).length > 0 ? string(abi.encodePacked(base)) : "";
        }
        return bytes(base).length > 0 ? string(abi.encodePacked(base, uint2str(tokenId))) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

  	function setTotalSupply(uint _totalSupply) public onlyOwner{
  	    maxCoviesSupply = _totalSupply;
  	}

    function claim(uint _claimCount) public payable {
        require(claimableSale == true, "Claiming Not Active");
        uint sent = msg.value;
        require(sent == mintPrice * _claimCount, "Did not send required eth");
        require(_claimCount > 0 && _claimCount <= totalClaimable[msg.sender], "You are not eligible to claim this many tokens");
        //ADD USER TO ARRAY
        claimers.push(msg.sender);
        //ADD USER CLAIMED
        totalClaimed[msg.sender] += _claimCount;
        //REDUCE USER CLAIMABLE
        totalClaimable[msg.sender] -= _claimCount;
    }

    function airdrop(uint _from, uint _to) public onlyOwner {
        // TODO: Re-this function in order to airdrop NFT to an input addresses array.

        for(uint i = _from; i < _to && i < claimers.length; i++){
            require(_tokenIdCounter.current() < maxCoviesSupply, "Max Supply Reached");

            for(uint j = 0; j < totalClaimed[claimers[i]]; j++){
                uint256 _tokenID = _tokenIdCounter.current();

                //REQUIRE TOKEN DOESNT EXIST
                require(!super._exists(_tokenID), "Token ID Already Exists");

                //MINT TO CLAIMERS ADDRESS
                _safeMint(claimers[i], _tokenID);
                _tokenIdCounter.increment();
            }
            totalClaimed[claimers[i]] = 0;
        }
    }

    function regularSaleMint(uint _count) public payable {
        require(regularSale == true, "Normal Sale Not Active");
        require(_count <= maxPerTransaction, "Over maxPerTransaction");
        require(msg.value == mintPrice * _count, "Insuffcient Amount Sent");

        require(_tokenIdCounter.current() < maxCoviesSupply, "At Max Supply");


        for(uint i = 0; i < _count; i++){
            uint256 _tokenID = _tokenIdCounter.current();
            require(!super._exists(_tokenID), "Token ID Exists");
            _safeMint(msg.sender, _tokenID);
            _tokenIdCounter.increment();
        }
    }
    function ownerMint(uint _count) public onlyOwner {
        require(_tokenIdCounter.current() + _count < maxCoviesSupply, "TOO MANY COVIES");
        for(uint i = 0; i < _count; i++){
            uint256 _tokenID = _tokenIdCounter.current();
            require(!super._exists(_tokenID), "Token ID Exists");
            require(_tokenIdCounter.current() < maxCoviesSupply, "At Max Supply");
            _safeMint(msg.sender, _tokenID);
            _tokenIdCounter.increment();
        }
    }
    function whitelistFunctions(uint iFunc, uint i) private view returns(address explicit){
        // TODO: Keep only one presale

        // if(iFunc==0){
        //     try oldContract.whiteListOne(i) returns (address _address) {
        //         return(_address);
        //     } catch {
        //         return(address(0));
        //     }
        // }
        // else if(iFunc==1){
        //     try oldContract.whiteListTwo(i) returns (address _address) {
        //         return(_address);
        //     } catch {
        //         return(address(0));
        //     }
        // }
    }


    // function pullWhitelist(uint _from, uint _to) public onlyOwner
    // {
    //     for(uint f = _from; f < _to; f++){
    //         bool tmp = false;
    //         for(uint i = 0; !tmp; i++){
    //             address tmpAddress = whitelistFunctions(f,i);
    //             if(tmpAddress != address(0)){
    //                 if(totalClaimable[tmpAddress] <= 0){
    //                     totalClaimable[tmpAddress] += oldContract.totalAvailableForUser(tmpAddress);
    //                 }
    //             } else {
    //                 tmp = true;
    //             }
    //         }
    //     }
    // }

    // function pullCurrentOwners(uint _to) public onlyOwner {
    //     uint oldTotalSupply = oldContract.totalSupply();
    //     if(_to > iOwner){
    //         for(uint i = iOwner; i <= oldTotalSupply && i < _to; i++){
    //             iOwner += 1;
    //             try oldContract.ownerOf(i) returns (address _address) {
    //                 if(_address != address(0)){
    //                     claimers.push(_address);
    //                     totalClaimed[_address] += 1;
    //                 }
    //             } catch {
    //             }
    //         }
    //     }
    // }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function flipClaimableSale() public onlyOwner {
        claimableSale = !claimableSale;
    }

    function flipRevealed() public onlyOwner {
        revealed = !revealed;
    }

    function flipRegularSale() public onlyOwner {
        regularSale = !regularSale;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function getClaimers() public view returns(address[] memory){
        return claimers;
    }
    function uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
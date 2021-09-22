// File contracts/RPCC.sol

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@///////////////////@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@/////*********************////(@@@@@@@@@@@@@@
//@@@@@@@@@@@@///*******,,,,,,,,,,,,,,,,,*******///@@@@@@@@@@@
//@@@@@@@@@///*****,,,,,.................,,,,,*****///@@@@@@@@
//@@@@@@@///***,,,,......               .....,,,,,***///@@@@@@
//@@@@@///,. %%%%%%&.         /%&%*         .&%%%%%% .,//(@@@@
//@@@@//*,.%#          &%###############%(          &%.,*//@@@
//@@@//**. %   &&&&###########################&&&&   % ,**//@@
//@@//***. %   &&###############################@&   % .***//@
//@///***. %   ###################################   % .***//@
//@//***,. %& ###########  (##########  ########### &% ,,***//
//@//***,,./%############    #######    ############% .,,***//
//@//***,. %###    %%@  @@@#%#######*#%  @@@%&    ###% .,***//
//@(//**. %       %%%%@@@@%           %@@@@%%%%      .% .**//@
//@@//*, %%      %%%%#                     %%%%%      %%.,*//@
//@@@//**. %%   #%%%         @@@@@@&         %%%&   %% .**//@@
//@@@@//***,./%&#%%%            @            %%%&&%..,***//@@@
//@@@@@///***,.  %%%%      [email protected]&%@@&/@@       %%%% ..,***///@@@@
//@@@@@@@///****,..  %%%                 %%%  .,,****///@@@@@@
//@@@@@@@@@///*****,,,...     /&&&/     ...,,,*****///@@@@@@@@
//@@@@@@@@@@@(///******,,,,,,,,,,,,,,,,,,,******///@@@@@@@@@@@
//@@@@@@@@@@@@@@@////***********************////@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@/////////////////////@@@@@@@@@@@@@@@@@@@


//Special thank you to the Cool Cats group for their guidance.
//Check out their amazing project at https://www.coolcatsnft.com/

//NFT Design Credit to GC Creative Co. Visit: http://gccreativeco.com.au/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC721Enumerable.sol';
import './Ownable.sol';

contract RPP is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private _reserved = 50;
    uint256 private _price = 0.02 ether;
    bool public _paused = true;

    // withdraw addresses
    address tArt = 0xbD2efA26DAFa5E6238faABe98Af06548aDe8806C;
    address tCharity = 0xC44FF08425375097e4337b48151499280c25268c;
    address tDev = 0xA27a7A5de203B0cbBA4cf2E7c7bcfA490B01fBE0;

    constructor(string memory baseURI) ERC721("Red Panda Pals", "RPP")  {
        setBaseURI(baseURI);

        // Testing the Safe Mint Function upon Deployment
        _safeMint( tArt, 0);
        _safeMint( tDev, 1);
    }

    function adopt(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Red Pandas are not quite ready yet for adoption" );
        require( num < 11,                              "Share your love of Red Pandas with others, there is a limit of 10" );
        require( supply + num < 10000 - _reserved,      "There are only so many Red Pandas left in the wild" );
        require( msg.value >= _price * num,             "Please re-evaluate your Ether sent" );

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

    // Just in case Eth acts up
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
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

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Red Pandas supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _art = address(this).balance / 20;
        uint256 _dev = address(this).balance / 25;
        uint256 _charity = address(this).balance - _art - _dev;
        require(payable(tArt).send(_art));
        require(payable(tDev).send(_dev));
        require(payable(tCharity).send(_charity));
    }
}
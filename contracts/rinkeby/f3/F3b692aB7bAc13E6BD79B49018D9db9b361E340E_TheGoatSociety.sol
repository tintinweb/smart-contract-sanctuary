// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./String.sol";
                                                 
contract TheGoatSociety is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    
    uint256 public sumonCost = 2;
    uint256 public sumonSupply = 0;
    uint256 public supply = 0;
    uint256 public price = 0.06 ether;
    uint256 public supplyL;
    uint256 public presaleSupplyL; //CONFIRM 
    uint256 public maxGoatMint = 10;
    uint256 public sumon_token_id = 10001;

    string public baseURI = "";
    bool public initiateSale = false;
    bool public initiatePreSale = false;

    bool public sumonActive = false;
    bool public calledWithdrawES = false;
    bool public presaleWhitelistActive = true;

    address[] public GoatPresale;

    address public partner1 = 0xc17B2B0E69954B4a12eb68a26F32487B53C0b11a;
    address public partner2 = 0x9dA11374A782497EB29FfFdd977D29a7c6D09e27;
    address public partner3 = 0xEF35c3Ed3B47f681F4d2D92630a65b91b007f24c;
    address public partner4 = 0x5b4a0c29161d8e1CbBCA06c32B353073d8bd351C;
    address public partner5 = 0xA099484Fba126dF3D753d20c7EcD8a283f00377F;
    address public partner6 = 0x89b8c1794BB616E5775BF8bdecd5567fa943b97B;
    address public partner7 = 0xC2071Daece8561381EDF09Bf58FE4D834490297E;
    address public partner8 = 0x7a984C84F0FafadaAb7D0395e6abe560E26Ff370;
    address public partner9 = 0xfA02f156c508DF8bC2fFd1fd34Ac7Fa4A598b6b5;
    address public partner10 = 0xf5D71a9d75AbCAB2fC79Cf7306Fbc38e33ED6f2D;
    address public partner11 = 0xb3CEd66d05495fdDD35e65CAa5Da7805755E51EF;
    
    address public partner12 = 0xc1Dda59c40ef5A972858610f680cd64c8d349cdd;
    address public partner13 = 0x3D2A172487456bF11F7300e8Ae0AB801A56eA5dB;
    address public splitAddy = 0xe58895118D9585340a341b17B0874f8C0EDce746;

    constructor(
        uint256 amount,
        uint256 presaleAmount,
        string memory _baseURI
    ) ERC721("Goat Society", "GS") {
        supplyL = amount;
        presaleSupplyL = presaleAmount;
        baseURI = _baseURI;
    }
    
    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, token_id.toString())) : "";
    }

    function flipValues(uint256 flip) external onlyOwner {
        if (flip == 0) {
            initiateSale = !initiateSale;
        } else if (flip == 1) {
            initiatePreSale = !initiatePreSale;
        } else if (flip == 2) {
            presaleWhitelistActive = !presaleWhitelistActive;
        } else if (flip == 3) {
            sumonActive = !sumonActive;
        }
    }
    
    function change_sumon_token(uint256 _sumon_token_id) external onlyOwner {
        sumon_token_id = _sumon_token_id;
    }
    
    function sumonAmount(uint256 _supplyLimit) external onlyOwner {
        require(_supplyLimit >= supply, "Error ");
        supplyL = _supplyLimit;
    }
    
    function sumon_maxGoatMint(uint256 _mintLimit) external onlyOwner {
        maxGoatMint = _mintLimit;
    }
    
    function sumon_mintPrice(uint256 _mintPrice) external onlyOwner {
        price = _mintPrice;
    }
    
    function set_uri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }




    function withdrawES() external onlyOwner {
        require(address(this).balance > 10 ether, "None");
        require(calledWithdrawES == false, "Already ran the withdraw method.");
        (bool withES,) = splitAddy.call{value: 10 ether}("");
        calledWithdrawES = true;
        require(withES, "Not enough ethereum to withdraw");
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "None");
        require(calledWithdrawES == true, "Already Ran");
        uint256 walletBalance = address(this).balance;
        
        (bool w1,) = partner12.call{value: walletBalance.mul(5).div(100)}(""); //5
        (bool w2,) = partner13.call{value: walletBalance.mul(5).div(100)}(""); //5
        
        partner1.call{value: walletBalance.mul(5).div(100)}; //5
        partner2.call{value: walletBalance.mul(5).div(100)}; //5
        partner3.call{value: walletBalance.mul(1).div(100)}; //1
        partner4.call{value: walletBalance.mul(5).div(100)}; //5
        partner5.call{value: walletBalance.mul(15).div(100)}; //15
        partner6.call{value: walletBalance.mul(145).div(1000)}; //14.5
        partner7.call{value: walletBalance.mul(295).div(1000)}; //29.5
        partner8.call{value: walletBalance.mul(10).div(100)}; //10
        partner9.call{value: walletBalance.mul(25).div(1000)}; //2.5
        partner10.call{value: walletBalance.mul(15).div(1000)}; //1.5
        partner11.call{value: walletBalance.mul(1).div(100)}; //1

        require(w1 && w2, "Failed withdraw");
    }
    
    //Incase withdraw() fails run this method
    function emergencyWithdraw() external onlyOwner {
        (bool withES,) = splitAddy.call{value: address(this).balance}("");
        require(withES, "Not enough ethereum to withdraw");
    }
    
    function populate_PreSaleWhitelist(address[] calldata preSaleWalletAddresses) external onlyOwner {
        delete GoatPresale;
        GoatPresale = preSaleWalletAddresses;
  	    return;
  	}
    
    function giveaway_goats() external onlyOwner {
        require(supply.add(25) <= supplyL, "Token error");

        uint256 token_id = supply;
        for(uint i = 0; i < 25; i++) {
            token_id += 1;
            supply = supply.add(1);
            _safeMint(msg.sender, token_id);
        }
    }
    
    function buy(uint nft) external payable {
        require(initiateSale, "Sale not available");
        require(nft <= maxGoatMint, "Too many");
        require(msg.value >= price.mul(nft), "Payment error");
        require(supply.add(nft) <= supplyL, "Token error");

        uint256 token_id = supply;
        for(uint i = 0; i < nft; i++) {
            token_id += 1;
            supply = supply.add(1);

            _safeMint(msg.sender, token_id);
        }
    }
    
    function buy_presale(uint nft) external payable {
        require(initiatePreSale, "Presale not available"); //YES
        require(nft <= maxGoatMint, "Too many"); //YES
        require(msg.value >= price.mul(nft), "Payment error"); //YES
        require(supply.add(nft) <= presaleSupplyL, "Token error"); //NO

        if (presaleWhitelistActive) {
            require(isWalletInPreSale(msg.sender), "Not in Presale");
            uint256 token_id = supply;
            for(uint i = 0; i < nft; i++) {
                token_id += 1;
                supply = supply.add(1);
        
                _safeMint(msg.sender, token_id);
            }
        } else {
            uint256 token_id = supply;
            for(uint i = 0; i < nft; i++) {
                token_id += 1;
                supply = supply.add(1);
        
                _safeMint(msg.sender, token_id);
            }
        }

    }
    
    function isWalletInPreSale(address _address) public view returns (bool) {
        for(uint256 i = 0; i < GoatPresale.length; i++) {
            if (GoatPresale[i] == _address) {
                return true;
            }
        }
        return false;
    }
    
    function sumon(uint256[] memory token_ids) public meetsOwnership(token_ids) {
        require(sumonActive, "Goat Summonings is not active");
        require(sumonSupply > 0, "No Summon Supply left");
        require(token_ids.length >= sumonCost, "Not enough Goats provided");
      
        for (uint256 i = 0; i < token_ids.length; i++) {
          _burn(token_ids[i]);
        }
        
        uint256 token_id = sumon_token_id;
        
        token_id += 1;
        sumon_token_id = sumon_token_id.add(1);
        _safeMint(msg.sender, token_id);

        sumonSupply -= 1;
    }
    
    function setsumonCost(uint256 newCost) public onlyOwner {
        require(newCost > 0, "sumonCost should be more than 0");
        sumonCost = newCost;
    }
         
    function setsumonSupply(uint256 newsumonSupply) public onlyOwner {
        sumonSupply = newsumonSupply;
    }
      
    modifier meetsOwnership(uint256[] memory token_ids) {
        for (uint256 i = 0; i < token_ids.length; i++) {
          require(this.ownerOf(token_ids[i]) == msg.sender, "You don't own these tokens");
        }
        _;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";

contract BabyBoomerNFT is ERC721, Ownable {
    
    uint[3] private tokenStats;
    uint[3] private presalesStats;
    uint[3] private mainsalesStats;
    uint public tokenQuota;
    uint public lastTokenMinted;

    uint public mintPrice;
    uint public redeemPrice;
    
    uint public state; 
    
    address[501] private presaleAllowlist;
    
    uint[10000] private mintLog;
    uint[10000] private redeemLog;

    mapping(address => uint) private addressQuotaLog;
    
    constructor() ERC721("BabyBoomerNFT", "BMR") {
        tokenStats = [10000, 0, 0];
        presalesStats = [500, 0, 0];
        mainsalesStats = [9500, 0, 0];
        tokenQuota = 100;
        lastTokenMinted = 500;
        mintPrice = 0.125 ether;
        redeemPrice = 0.08 ether;
        state = 0;
    }
    
    modifier quotaLeft {
        require(addressQuotaLog[msg.sender] <= tokenQuota, "This account has exceeded its quota"); _;
    }
    
    function getStats(uint forState) public view onlyOwner returns (uint[3] memory) {
        if (forState ==  1) {
            return presalesStats;
        } else if (forState == 2 || forState == 3) {
            return mainsalesStats;
        } else {
            return tokenStats;
        }
    }

    function setPresaleAllowlist(address[501] memory allowlist) public onlyOwner {
        presaleAllowlist = allowlist;
    }
    
    function getPresaleAllowlist() public view onlyOwner returns (address[501] memory) {
        return presaleAllowlist;
    }

    function getMyPresaleTokenId() public view returns (uint) {
        uint tokenId = 0;
        for (uint i=0; i<presaleAllowlist.length; i++) {
            if (presaleAllowlist[i] == msg.sender) {
                tokenId = i;
                break;
            }
        }
        return tokenId;
    }

    function getState() public view returns (string memory) {
        if (state == 1) {
            return "presale";
        } else if (state == 2) {
            return "mint";
        } else if (state == 3) {
            return "redeem";
        } else {
            return "inactive";
        }
    }

    function setState(uint newState) public onlyOwner {
        if (newState == 1) {
            state = 1;
        } else if (newState == 2) {
            state = 2;
        } else if (newState == 3) {
            state = 3;
        } else {
            state = 0;
        }
    }

    function currentBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawBalance() public onlyOwner {
        uint withdrawAmount_50 = address(this).balance * 50 / 100;
        uint withdrawAmount_48 = address(this).balance * 48 / 100;
        uint withdrawAmount_2 = address(this).balance * 2 / 100;
        payable(0x22af82800A32e1191A8FF4b527D23530140CaAfA).transfer(withdrawAmount_48);
        payable(0x5344F3bBB45541988a7d44651922c5575FBc8E17).transfer(withdrawAmount_50);
        payable(0x02Ee1B9F5f3C5fb2aa14b78Dc301b618f5f93C22).transfer(withdrawAmount_2);
    }
    
    function _mintBox(uint quantity) private quotaLeft {
        require(state == 1 || state == 2, "Minting is not open");
        if (state == 1) {
            require(mintLog[quantity] == 0, "This token has already been minted");
            require(presaleAllowlist[quantity] == msg.sender, "The supplied tokenId is not reserved for this wallet address");
            _safeMint(msg.sender, quantity);
            addressQuotaLog[msg.sender] = addressQuotaLog[msg.sender] + 1;
            mintLog[quantity] = 1;
            tokenStats[1] = tokenStats[1] + 1;
            presalesStats[1] = presalesStats[1] + 1;
            emit Minted(msg.sender, quantity);
        } else if (state == 2) {
            require(quantity == 2 || quantity == 5 || quantity == 10, "Invalid quantity supplied");
            for (uint i=0; i<quantity; i++) {
                lastTokenMinted = lastTokenMinted + 1;
                _safeMint(msg.sender, lastTokenMinted);
                addressQuotaLog[msg.sender] = addressQuotaLog[msg.sender] + 1;
                mintLog[lastTokenMinted] = 1;
                tokenStats[1] = tokenStats[1] + 1;
                mainsalesStats[1] = mainsalesStats[1] + 1;
                emit Minted(msg.sender, lastTokenMinted);
            }
        }
    }
    
    function mint(uint quantity) public payable quotaLeft {
        if (state == 1) {
            require(msg.value == mintPrice, "Incorrect amount supplied");
        } else if (state == 2) {
            require(msg.value == mintPrice * quantity, "Incorrect amount supplied");
        }
        _mintBox(quantity);
    }
    
    function ownerMint(uint quantity) public quotaLeft onlyOwner {
        _mintBox(quantity);
    }
    
    function _redeem(uint tokenId) public payable {
        require(state == 3, "Redemption is not currently enabled");
        require(redeemLog[tokenId] == 0, "This token has already been redeemed");
        redeemLog[tokenId] = 1;
        tokenStats[2] = tokenStats[2] + 1;
        if (tokenId <= presalesStats[0]) {
            presalesStats[2] = presalesStats[2] + 1;
        } else {
            mainsalesStats[2] = mainsalesStats[2] + 1;
        }
    }
    
    function redeem(uint tokenId) public payable {
        require(msg.value == redeemPrice, "The amount offered is not the correct redeem price");
        _redeem(tokenId);
    }
    
    function ownerRedeem(uint tokenId) public onlyOwner {
        _redeem(tokenId);
    }
    
    function unRedeem(uint tokenId) public onlyOwner {
        require(redeemLog[tokenId] > 0, "This is not a valid tokenId, or has not yet been redeemed");
        redeemLog[tokenId] = 0;
        tokenStats[2] = tokenStats[2] - 1;
        if (tokenId <= presalesStats[0]) {
            presalesStats[2] = presalesStats[2] - 1;
        } else {
            mainsalesStats[2] = mainsalesStats[2] - 1;
        }
    }
    
    function isRedeemed(uint tokenId) public view returns(uint) {
        return redeemLog[tokenId];
    }
    
    event PermanentURI(string _value, uint256 indexed _id);
    event Minted(address sender, uint tokenId);
    
    function contractURI() public pure returns (string memory) {
        return "https://babyboomernft.com/data/babyboomernft.json";
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }
    
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("https://babyboomernft.com/meta/", uint2str(tokenId)));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}
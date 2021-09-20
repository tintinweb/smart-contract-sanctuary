// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NiftySaxSpheres is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    uint256 public constant STANDARD_PRICE = 30000000000000000; // 0.03 ETH
    uint256 public constant DISCOUNT_PRICE = 20000000000000000; // 0.02 ETH
    uint256 public MAX_SUPPLY = 385;
    uint8 public salePhase = 0; // 0 = inactive, 1 = mint-pass sale, 2 = public sale
    string public PROVENANCE = "94f2a98eb86261417f0b1c891c9bcf0b2720b8c67270b589262783051a6d8511";
    
    string private _baseURIextended;
    mapping(address => bool) private mintPassAddresses;
    mapping(address => uint256) private referrals;

    constructor() ERC721("Nifty Sax Spheres", "NSS") {
        // list of pre-sale mints
        _safeMint(0x274a434F95CfE49702df41022F2Fdb629267F3C8, totalSupply());
        _safeMint(0x37A25c28c01A1f935bF71B898657BE91f47e66e0, totalSupply());
        _safeMint(0xdecBB1759c9550A0D2a9e501626e39B3cDa2EAED, totalSupply());
        _safeMint(0xCC0960243d099BCaE96c0D1AEACDdA01434d2ebc, totalSupply());
        _safeMint(0x5b34f08E224E9218cD2c15109660Bcc4a01c5eEb, totalSupply());
        _safeMint(0x5bc49bAC20D2db1D3C051f1dF6F7b7E250Ac907B, totalSupply());
        _safeMint(0x79fF435184674986312275a031999D689be9d104, totalSupply());
        _safeMint(0xc8c759157121080f3aAB6D0d5c2fa8573c134262, totalSupply());
        _safeMint(0x48CD130949880D951C3846F653DdCbDd28a7A6f1, totalSupply());
        _safeMint(0x48CD130949880D951C3846F653DdCbDd28a7A6f1, totalSupply());

        
        // list of mint-pass mintPassAddresses
        mintPassAddresses[0x14D673b98fCeB1D50ce48341Ea11f32a5250D4C0] = true;
        mintPassAddresses[0xa2E67BfC520f8586f7f1170b1eb52741904697D5] = true;
        mintPassAddresses[0xFc5236d8C803A3ef420eCbA50A91c6354fc22137] = true;
        mintPassAddresses[0xdecBB1759c9550A0D2a9e501626e39B3cDa2EAED] = true;
        mintPassAddresses[0x11a22b262e505d355F975e1E48A365b5D4811Ae0] = true;
        mintPassAddresses[0xdB5dFa23a9b606a918Af7f2a710e69E25Af47251] = true;
        mintPassAddresses[0x0d3b60DE0FdF7Ac4c1400C3C7B412dc75B4B342D] = true;
        mintPassAddresses[0x0090DdE383865bC21a72639313975CDB67D2D612] = true;
        mintPassAddresses[0x74648Ba6f408a1dECfDe319CEf04f1B332949B38] = true;
        mintPassAddresses[0x55CF11743818B5f0B5440b6E85A003C604d1AF01] = true;
        mintPassAddresses[0xB95f01cb0c887Eae5ABD551bD63B642b9F5C4949] = true;
        mintPassAddresses[0x891Ae4Cd23EE4936A689F5Dd1D32d4cBE77a2dE4] = true;
        mintPassAddresses[0xa3991B76c7282db0652f45C7Ed080CF00fC3147A] = true;
        mintPassAddresses[0x92E8443Db866C722276B0aA93734770a2dE79CEB] = true;
        mintPassAddresses[0xff2450085510b5Eb86c7f9451d5FBc0cA5a793AA] = true;
        mintPassAddresses[0x11a9583750806c3f521254c8E930991cd6139B30] = true;
        mintPassAddresses[0x58F579b62f86d27b931Aa08C332368b880d118E4] = true;
        mintPassAddresses[0xF6f7048A2Ec27fdA605C2a1f61eba95465a78D87] = true;
    }
    
    function changeSalePhase(uint8 phase) public onlyOwner {
        salePhase = phase;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function reserveTokens(uint numberOfTokens) public onlyOwner {
        require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Mint would exceed max supply of tokens");
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function claimFreeMint() public {
        require(referrals[msg.sender] > 4, "You don't have enough referrals yet");
        require(salePhase > 0, "Sale is not active at the moment");
        require((totalSupply() + 1) <= MAX_SUPPLY, "Mint would exceed max supply of tokens");
        referrals[msg.sender] -= 5;
        _safeMint(msg.sender, totalSupply());
    }
    
    function getReferrals() public view returns(uint256) {
        return referrals[msg.sender];
    }
    
    function mintSphere(uint numberOfTokens, address referrer) public payable {
        require(referrer != msg.sender, "Referrer cannot be the same as sender");
        mintSphere(numberOfTokens);
        referrals[referrer] += numberOfTokens;
    }
    
    function mintSphere(uint numberOfTokens) public payable {
        require(salePhase > 0, "Sale is not active at the moment");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(calculateMintCost(numberOfTokens) == msg.value, "Sent ether value is incorrect");
        if (salePhase == 1) {
            require(mintPassAddresses[msg.sender] == true, "Address is not authorised for the mint-pass sale");
        }
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function calculateMintCost(uint numberOfTokens) internal pure returns(uint) {
        uint cost = 0;
        for (uint i = 0; i < numberOfTokens; i++) {
            if (i < 4) {
                cost += STANDARD_PRICE;
            } else {
                cost += DISCOUNT_PRICE;
            }
        }
        return cost;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
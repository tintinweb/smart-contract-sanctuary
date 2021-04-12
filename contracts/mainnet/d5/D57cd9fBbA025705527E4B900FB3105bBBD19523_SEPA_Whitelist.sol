// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Ownable.sol" ;
import "../SafeMath.sol";

//@title SEPA Token contract interface
interface SEPA_Token {                                     
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

//@title SEPA Whitelist Contract
contract SEPA_Whitelist is Ownable {
    using SafeMath for uint256 ;
    uint256 public SEPAPrice ;
    
    address public token_addr ; 
    SEPA_Token token_contract = SEPA_Token(token_addr) ;
    
    event bought(address buyer, uint256 amount) ;
    event priceAdjusted(uint256 oldPrice, uint256 newPrice) ; 

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public claimed_amount;
    
    uint256 public total_locked = 0;
    
    uint256 public start_timestamp = block.timestamp;

    constructor(uint256 SEPAperETH) {
        SEPAPrice = SEPAperETH ;
        
        whitelist[0x0e4DA865E7021c905fD9F6e82915Cf30B881dA20] = true;
        whitelist[0x737624ED38955055E04F7429A71aaA4367cc93C8] = true;
        whitelist[0xf9Eb4b0670AB8Bb86aE33eb5ac34Da2c08D58168] = true;
        whitelist[0xb30aEC278bB30C5EbfDAf0b888f80cD1DC944cAA] = true;
        whitelist[0xaEa9Cc119Ad2de6c4161ad869f57895360a54A21] = true;
        whitelist[0x1db75Bc3F7ad4B23Fd91a00a6c23871E3c0c5dbd] = true;
        whitelist[0xbcbE910D3E2FE72DC14C579267228e3872Ab8C89] = true;
        whitelist[0x707ED597C748bAfcA103A5edC15D986FF0DB5588] = true;
        whitelist[0xBD5b72A63834463FA5980aAd3a11167Ae6094b65] = true;
        whitelist[0xf239331bB94CBE92A6A4eEb0b78B85B1087Ee5D6] = true;
        whitelist[0xA520dD26743ff11aC9aEEFAbDb81c158D3e97618] = true;
        whitelist[0x1444014b0d94E6C4BecC7F135E3799828AEFEfA1] = true;
        whitelist[0x78B5a97779841357777F876cB340d99E8f20A2c7] = true;
        whitelist[0xe11D29f39DC3cb2a8EeD882b67D1C5cC4A1C08D9] = true;
        whitelist[0xd35483f78Af577bf7cc47F67061373231110aF28] = true;
        whitelist[0xfb6483C0D2c0313624B2813F0c819Fba2a246699] = true;
        whitelist[0xD920B68db744CBDf5bc8f63B6B2Bd560292aAB5d] = true;
        whitelist[0x4BaF591F801E7DCC74C04de25C501D2AFDB2f847] = true;
        whitelist[0x9c8D8a0878354553fD4298bFef6FddC42985Ebf3] = true;
        whitelist[0xF009d057f8210c380c68D383aa7FFeE8f9E6DF74] = true;
        whitelist[0x72786105cAb6038B90b1952405eC55d05068b9BD] = true;
        whitelist[0x3f1b1Af91538ad424FFf41f9495525265e87E4BE] = true;
        whitelist[0xd21E123380A89f885BF31335BE93a80795F8E76c] = true;
        whitelist[0x77DfC846Fd83dC17b988338559E8f50EC1E705Be] = true;
        whitelist[0x93323ce6D04624640A4A361303A7f1E119578EF5] = true;
        whitelist[0x753855737f53134d2877f2d306Ad66Ca8bAe23Cf] = true;
        whitelist[0x94728E647dCd59Bf0CBF6A9808aBE2B0269a197C] = true;
        whitelist[0x394E4e5836EbA5c30d29A0A38A5D63Badc47ae9E] = true;
        whitelist[0x95DC13cb5bB99fB2f1705e7D70ffA1F9E2573641] = true;
        whitelist[0x4Ff920CF975fc14EdC96f61bA80a88416ef6d219] = true;
        whitelist[0x78B02F3dA4439983bCA5e8768d538791ECfF5784] = true;
        whitelist[0x7CFFf2A8690512bCDd61c36d099dADa5543fFa08] = true;
        whitelist[0xE156d8b2A3Bca42E496E539667FE585351C0e057] = true;
        whitelist[0x7650376aD17592801bb2CC73BC08F4e777DEa7F5] = true;
        whitelist[0xf10a9E7DB6837BEc7CEBEBDd2867991C5aA2785F] = true;
        whitelist[0x63ee8D1aE82a9511bEE28256d24880E713d78DD3] = true;
        whitelist[0x7B47bf67667C35DF4306b87Ae16A1eB467FD004D] = true;
        whitelist[0xB68764058616Ff2B704F432f69BFB21F85C06bf7] = true;
        whitelist[0x78B02F3dA4439983bCA5e8768d538791ECfF5784] = true;
        whitelist[0x27f1d1944524B30329f68716a14f3fC201080820] = true;
        whitelist[0x27f1d1944524B30329f68716a14f3fC201080820] = true;
        whitelist[0x9d156bc7c8768294510A4A41883d5A4EB15b15E3] = true;
        whitelist[0xba30963F47A2d33476E922Faa55bEc570C433dD0] = true;
        whitelist[0x78529a5325a7CbFe0208A6fE99A829EA28b09946] = true;
        whitelist[0x461e76A4fE9f27605d4097A646837c32F1ccc31c] = true;
        whitelist[0x8e47cD04F8D64E6Dd0b9847F65923Dc0141EF8a6] = true;
        whitelist[0x29Bf6652e795C360f7605be0FcD8b8e4F29a52d4] = true;
        whitelist[0x584CB319A932f5409e047D8F2eFd5f92D2AdB40a] = true;
        whitelist[0x9d156bc7c8768294510A4A41883d5A4EB15b15E3] = true;
        whitelist[0x5eE42438d0D8fc399C94ef3543665E993e847b49] = true;
        whitelist[0x96427109835D2CB6ba483A351C576B127Cb28a41] = true;
        whitelist[0x419e1394f733bC53cB8A925555548E697381b25b] = true;
        whitelist[0x4A9De51F3AFcA7051900766082aFd4cab6d65952] = true;
        whitelist[0x0FC96Be07b23193b2d2bC95eeA8133ABEC71dcb6] = true;
        whitelist[0x5e5F4BD175dB70f437397b497e23638D445C9313] = true;
        whitelist[0x9E48aEbb11D9eb339f857E2dA9Fde629e838ff01] = true;
        whitelist[0x5eE42438d0D8fc399C94ef3543665E993e847b49] = true;
        whitelist[0x9822C731b38009A05384fFd757c854f71CE751F9] = true;
        whitelist[0xF61306834Daf15431d74d5531C9019ED198C3411] = true;
        whitelist[0x536AC951171f25120c6688998966D6760035e8c5] = true;
        whitelist[0x4063B329F62460b2f82E918ad930D5577A6B576A] = true;
        whitelist[0x75Fe3943a6C8866e1C41e1F35c74A9fB7a77b835] = true;
        whitelist[0x2d92C9290352df0F6D29867d39D0f0837557544F] = true;
        whitelist[0xe3B121a6E658Ee729d738bebD78aa4Ee6392E3A2] = true;
        whitelist[0x53091293A36D38D1480Ac896995ABFF4010c3487] = true;
        whitelist[0xF96387A496344fD7fc55Dc146825274569ff001f] = true;
        whitelist[0xc0dCC094f370bBc6EcC832f6196136437f458f74] = true;
        whitelist[0x9fDea06ECD83db688f6f6c75891850A038A2B34b] = true;
        whitelist[0x3e2A824e075617410DCE55d57E6f4aDdA4947de4] = true;
        whitelist[0x8aD8998de8623a2bDd943ebA292AC07aab791E6e] = true;
        whitelist[0x65F32f9172146b778373818f99B0b25c52bF275d] = true;
        whitelist[0x01AED9E1A9A07a9CF24950744896141B9157F295] = true;
        whitelist[0x55fA71485377006A712De6F1c89642c621B17D79] = true;
        whitelist[0x9e1833861F9850Fa5542831466c915B355d913E6] = true;
        whitelist[0xDD9B9DF9c4d8d9B602887a5d0302f6BF364F2FeB] = true;
        whitelist[0x360E3F79EAefb9dFdf29219ea763F0C38bfb0362] = true;
        whitelist[0x8842d7fFFc929C7BFfaEfdB29c10765442012B4d] = true;
        whitelist[0xc2137343511c93C15cF46A0D2EA1b12df309AEd4] = true;
        whitelist[0x8C48b2793ad94bC666A365432E4Bb84F3f2cAd37] = true;
        whitelist[0x4a8040Ba32cecc541C8645e4D8a3234492fdB1dC] = true;
        whitelist[0xBa452110D50aa94DE56D9e7Fa8A7AA1Cd998C9A7] = true;
        whitelist[0x0869fD08Ff42889e11E09A0c2B46Ce3d163a25D5] = true;
        whitelist[0xC3d7163c52002eE6Ade9f2c0dF148deBD1512D11] = true;
        whitelist[0xe5CECC31e72F4ecCd717a17b4E62Cb6b4C5125df] = true;
        whitelist[0x815865eB8BF8A641D6293723fc72fc110D4f1cF8] = true;
        whitelist[0x3BE1cE4D2410Ae605310a3d71A12059002ad5Cea] = true;
        whitelist[0x8B9be15bDb5190c8A2A210Bef21f0EfBEEA738Cb] = true;
        whitelist[0x711Bbb078AAd36143f178ce63246d7338490AE2B] = true;
        whitelist[0x65b4E64E3e6D4a155f8193eC608c1a49e914A7aF] = true;
    }

    /**
     * @dev Multiply two integers with extra checking the result
     * @param   a Integer 1 
     *          b Integer 2
     */
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0 ;
        } else {
            uint256 c = a * b ;
            assert(c / a == b) ;
            return c ;
        }
    }
    
    /**
     * @dev Divide two integers with checking b is positive
     * @param   a Integer 1 
     *          b Integer 2
     */
    function safeDivide(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); 
        uint256 c = a / b;

        return c;
    }
    
    /**
     * @dev Set SEPA Token contract address
     * @param addr Address of SEPA Token contract
     */
    function set_token_contract(address addr) external onlyOwner {
        token_addr = addr ;
        token_contract = SEPA_Token(token_addr) ;
    }

    /**
     * @dev Buy SEPA tokens directly from the contract
     */
    function buy_SEPA() public payable returns (bool success) {
        require(block.timestamp >= 1617386400, "Contract not yet active") ; //4 April 2021 6PM UTC
        require(whitelist[msg.sender], "User not on whitelist"); 
        require(msg.value <= 3 ether, "Transaction value exceeds 3 ether");
        require(claimed_amount[msg.sender].add(msg.value) <= 3 ether, "Maximum amount reached");
        uint256 scaledAmount = safeMultiply(msg.value, SEPAPrice) ;
        require((token_contract.balanceOf(address(this))).sub(total_locked) >= scaledAmount, "Contract token balance not sufficient") ;

        uint256 unlocked = (scaledAmount.mul(80)).div(100);
        uint256 locked = scaledAmount.sub(unlocked);
        
        total_locked += locked; 
        claimed_amount[msg.sender] += msg.value ; 
        
        balances[msg.sender] += scaledAmount.sub(unlocked);

        token_contract.transfer(msg.sender, unlocked) ;
        
        emit bought(msg.sender, scaledAmount) ; 
    
        success = true ; 
    }
    
    function claim_SEPA() external returns (bool success) {
        require(block.timestamp > start_timestamp + 2592000);
        
        
        balances[msg.sender] = 0;
        token_contract.transfer(msg.sender, balances[msg.sender]);
        
        success = true;
    }
    
    /**
     * @dev Fallback function for when a user sends ether to the contract
     * directly instead of calling the function
     */
    receive() external payable {
        buy_SEPA() ; 
    }

    /**
     * @dev Adjust the SEPA token price
     * @param   SEPAperETH the amount of SEPA a user receives for 1 ETH
     */
    function adjustPrice(uint SEPAperETH) external onlyOwner {
        emit priceAdjusted(SEPAPrice, SEPAperETH) ; 
        
        SEPAPrice = SEPAperETH ; 
        
    }

    /**
     * @dev End the SEPA token distribution by sending all leftover tokens and ether to the contract owner
     */
    function endSEPASeed() external onlyOwner {             
        require(token_contract.transfer(owner(), token_contract.balanceOf(address(this)))) ;

        msg.sender.transfer(address(this).balance) ;
    }
    
    function updateWhitelist(address _addr, bool _bool) external onlyOwner {
        whitelist[_addr] = _bool;
    }
}
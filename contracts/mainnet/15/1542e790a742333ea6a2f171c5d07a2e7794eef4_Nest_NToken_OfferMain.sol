/**
 *Submitted for verification at Etherscan.io on 2020-08-11
*/

pragma solidity 0.6.0;

/**
 * @title Offering contract
 * @dev Offering logic and mining logic
 */
contract Nest_NToken_OfferMain {
    
    using SafeMath for uint256;
    using address_make_payable for address;
    using SafeERC20 for ERC20;
    
    // Offering data structure
    struct Nest_NToken_OfferPriceData {
        // The unique identifier is determined by the position of the offer in the array, and is converted to each other through a fixed algorithm (toindex(), toaddress())
        address owner;                                  //  Offering owner
        bool deviate;                                   //  Whether it deviates 
        address tokenAddress;                           //  The erc20 contract address of the target offer token
        
        uint256 ethAmount;                              //  The ETH amount in the offer list
        uint256 tokenAmount;                            //  The token amount in the offer list
        
        uint256 dealEthAmount;                          //  The remaining number of tradable ETH
        uint256 dealTokenAmount;                        //  The remaining number of tradable tokens
        
        uint256 blockNum;                               //  The block number where the offer is located
        uint256 serviceCharge;                          //  The fee for mining
        // Determine whether the asset has been collected by judging that ethamount, tokenamount, and servicecharge are all 0
    }
    
    Nest_NToken_OfferPriceData [] _prices;                              //  Array used to save offers
    Nest_3_VoteFactory _voteFactory;                                    //  Voting contract
    Nest_3_OfferPrice _offerPrice;                                      //  Price contract
    Nest_NToken_TokenMapping _tokenMapping;                             //  NToken mapping contract
    ERC20 _nestToken;                                                   //  nestToken
    Nest_3_Abonus _abonus;                                              //  Bonus pool
    uint256 _miningETH = 10;                                            //  Offering mining fee ratio
    uint256 _tranEth = 1;                                               //  Taker fee ratio
    uint256 _tranAddition = 2;                                          //  Additional transaction multiple
    uint256 _leastEth = 10 ether;                                       //  Minimum offer of ETH
    uint256 _offerSpan = 10 ether;                                      //  ETH Offering span
    uint256 _deviate = 10;                                              //  Price deviation - 10%
    uint256 _deviationFromScale = 10;                                   //  Deviation from asset scale
    uint256 _ownerMining = 5;                                           //  Creator ratio
    uint256 _afterMiningAmount = 0.4 ether;                             //  Stable period mining amount
    uint32 _blockLimit = 25;                                            //  Block interval upper limit
    
    uint256 _blockAttenuation = 2400000;                                //  Block decay interval
    mapping(uint256 => mapping(address => uint256)) _blockOfferAmount;  //  Block offer times - block number=>token address=>offer fee
    mapping(uint256 => mapping(address => uint256)) _blockMining;       //  Offering block mining amount - block number=>token address=>mining amount
    uint256[10] _attenuationAmount;                                     //  Mining decay list
    
    //  Log token contract address
    event OfferTokenContractAddress(address contractAddress);           
    //  Log offering contract, token address, amount of ETH, amount of ERC20, delayed block, mining fee
    event OfferContractAddress(address contractAddress, address tokenAddress, uint256 ethAmount, uint256 erc20Amount, uint256 continued,uint256 mining);         
    //  Log transaction sender, transaction token, transaction amount, purchase token address, purchase token amount, transaction offering contract address, transaction user address
    event OfferTran(address tranSender, address tranToken, uint256 tranAmount,address otherToken, uint256 otherAmount, address tradedContract, address tradedOwner);        
    //  Log current block, current block mined amount, token address
    event OreDrawingLog(uint256 nowBlock, uint256 blockAmount, address tokenAddress);
    //  Log offering block, token address, token offered times
    event MiningLog(uint256 blockNum, address tokenAddress, uint256 offerTimes);
    
    /**
     * Initialization method
     * @param voteFactory Voting contract address
     **/
    constructor (address voteFactory) public {
        Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        _voteFactory = voteFactoryMap;                                                                 
        _offerPrice = Nest_3_OfferPrice(address(voteFactoryMap.checkAddress("nest.v3.offerPrice")));            
        _nestToken = ERC20(voteFactoryMap.checkAddress("nest"));                                                          
        _abonus = Nest_3_Abonus(voteFactoryMap.checkAddress("nest.v3.abonus"));
        _tokenMapping = Nest_NToken_TokenMapping(address(voteFactoryMap.checkAddress("nest.nToken.tokenMapping")));
        
        uint256 blockAmount = 4 ether;
        for (uint256 i = 0; i < 10; i ++) {
            _attenuationAmount[i] = blockAmount;
            blockAmount = blockAmount.mul(8).div(10);
        }
    }
    
    /**
     * Reset voting contract method
     * @param voteFactory Voting contract address
     **/
    function changeMapping(address voteFactory) public onlyOwner {
        Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        _voteFactory = voteFactoryMap;                                                          
        _offerPrice = Nest_3_OfferPrice(address(voteFactoryMap.checkAddress("nest.v3.offerPrice")));      
        _nestToken = ERC20(voteFactoryMap.checkAddress("nest"));                                                   
        _abonus = Nest_3_Abonus(voteFactoryMap.checkAddress("nest.v3.abonus"));
        _tokenMapping = Nest_NToken_TokenMapping(address(voteFactoryMap.checkAddress("nest.nToken.tokenMapping")));
    }
    
    /**
     * Offering method
     * @param ethAmount ETH amount
     * @param erc20Amount Erc20 token amount
     * @param erc20Address Erc20 token address
     **/
    function offer(uint256 ethAmount, uint256 erc20Amount, address erc20Address) public payable {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        address nTokenAddress = _tokenMapping.checkTokenMapping(erc20Address);
        require(nTokenAddress != address(0x0));
        //  Judge whether the price deviates
        uint256 ethMining;
        bool isDeviate = comparativePrice(ethAmount,erc20Amount,erc20Address);
        if (isDeviate) {
            require(ethAmount >= _leastEth.mul(_deviationFromScale), "EthAmount needs to be no less than 10 times of the minimum scale");
            ethMining = _leastEth.mul(_miningETH).div(1000);
        } else {
            ethMining = ethAmount.mul(_miningETH).div(1000);
        }
        require(msg.value >= ethAmount.add(ethMining), "msg.value needs to be equal to the quoted eth quantity plus Mining handling fee");
        uint256 subValue = msg.value.sub(ethAmount.add(ethMining));
        if (subValue > 0) {
            repayEth(address(msg.sender), subValue);
        }
        //  Create an offer
        createOffer(ethAmount, erc20Amount, erc20Address,isDeviate, ethMining);
        //  Transfer in offer asset - erc20 to this contract
        ERC20(erc20Address).safeTransferFrom(address(msg.sender), address(this), erc20Amount);
        _abonus.switchToEthForNTokenOffer.value(ethMining)(nTokenAddress);
        //  Mining
        if (_blockOfferAmount[block.number][erc20Address] == 0) {
            uint256 miningAmount = oreDrawing(nTokenAddress);
            Nest_NToken nToken = Nest_NToken(nTokenAddress);
            nToken.transfer(nToken.checkBidder(), miningAmount.mul(_ownerMining).div(100));
            _blockMining[block.number][erc20Address] = miningAmount.sub(miningAmount.mul(_ownerMining).div(100));
        }
        _blockOfferAmount[block.number][erc20Address] = _blockOfferAmount[block.number][erc20Address].add(ethMining);
    }
    
    /**
     * @dev Create offer
     * @param ethAmount Offering ETH amount
     * @param erc20Amount Offering erc20 amount
     * @param erc20Address Offering erc20 address
     **/
    function createOffer(uint256 ethAmount, uint256 erc20Amount, address erc20Address, bool isDeviate, uint256 mining) private {
        // Check offer conditions
        require(ethAmount >= _leastEth, "Eth scale is smaller than the minimum scale");                                                 
        require(ethAmount % _offerSpan == 0, "Non compliant asset span");
        require(erc20Amount % (ethAmount.div(_offerSpan)) == 0, "Asset quantity is not divided");
        require(erc20Amount > 0);
        // Create offering contract
        emit OfferContractAddress(toAddress(_prices.length), address(erc20Address), ethAmount, erc20Amount,_blockLimit,mining);
        _prices.push(Nest_NToken_OfferPriceData(
            msg.sender,
            isDeviate,
            erc20Address,
            
            ethAmount,
            erc20Amount,
            
            ethAmount, 
            erc20Amount, 
            
            block.number,
            mining
        ));
        // Record price
        _offerPrice.addPrice(ethAmount, erc20Amount, block.number.add(_blockLimit), erc20Address, address(msg.sender));
    }
    
    // Convert offer address into index in offer array
    function toIndex(address contractAddress) public pure returns(uint256) {
        return uint256(contractAddress);
    }
    
    // Convert index in offer array into offer address 
    function toAddress(uint256 index) public pure returns(address) {
        return address(index);
    }
    
    /**
     * Withdraw offer assets
     * @param contractAddress Offer address
     **/
    function turnOut(address contractAddress) public {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        uint256 index = toIndex(contractAddress);
        Nest_NToken_OfferPriceData storage offerPriceData = _prices[index];
        require(checkContractState(offerPriceData.blockNum) == 1, "Offer status error");
        // Withdraw ETH
        if (offerPriceData.ethAmount > 0) {
            uint256 payEth = offerPriceData.ethAmount;
            offerPriceData.ethAmount = 0;
            repayEth(offerPriceData.owner, payEth);
        }
        // Withdraw erc20
        if (offerPriceData.tokenAmount > 0) {
            uint256 payErc = offerPriceData.tokenAmount;
            offerPriceData.tokenAmount = 0;
            ERC20(address(offerPriceData.tokenAddress)).safeTransfer(address(offerPriceData.owner), payErc);
            
        }
        // Mining settlement
        if (offerPriceData.serviceCharge > 0) {
            mining(offerPriceData.blockNum, offerPriceData.tokenAddress, offerPriceData.serviceCharge, offerPriceData.owner);
            offerPriceData.serviceCharge = 0;
        }
    }
    
    /**
    * @dev Taker order - pay ETH and buy erc20
    * @param ethAmount The amount of ETH of this offer
    * @param tokenAmount The amount of erc20 of this offer
    * @param contractAddress The target offer address
    * @param tranEthAmount The amount of ETH of taker order
    * @param tranTokenAmount The amount of erc20 of taker order
    * @param tranTokenAddress The erc20 address of taker order
    */
    function sendEthBuyErc(uint256 ethAmount, uint256 tokenAmount, address contractAddress, uint256 tranEthAmount, uint256 tranTokenAmount, address tranTokenAddress) public payable {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        uint256 serviceCharge = tranEthAmount.mul(_tranEth).div(1000);
        require(msg.value == ethAmount.add(tranEthAmount).add(serviceCharge), "msg.value needs to be equal to the quotation eth quantity plus transaction eth plus");
        require(tranEthAmount % _offerSpan == 0, "Transaction size does not meet asset span");
        
        //  Get the offer data structure
        uint256 index = toIndex(contractAddress);
        Nest_NToken_OfferPriceData memory offerPriceData = _prices[index]; 
        //  Check the price, compare the current offer to the last effective price
        bool thisDeviate = comparativePrice(ethAmount,tokenAmount,tranTokenAddress);
        bool isDeviate;
        if (offerPriceData.deviate == true) {
            isDeviate = true;
        } else {
            isDeviate = thisDeviate;
        }
        //  Limit the taker order only be twice the amount of the offer to prevent large-amount attacks
        if (offerPriceData.deviate) {
            //  The taker order deviates  x2
            require(ethAmount >= tranEthAmount.mul(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
        } else {
            if (isDeviate) {
                //  If the taken offer is normal and the taker order deviates x10
                require(ethAmount >= tranEthAmount.mul(_deviationFromScale), "EthAmount needs to be no less than 10 times of transaction scale");
            } else {
                //  If the taken offer is normal and the taker order is normal x2
                require(ethAmount >= tranEthAmount.mul(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
            }
        }
        
        // Check whether the conditions for taker order are satisfied
        require(checkContractState(offerPriceData.blockNum) == 0, "Offer status error");
        require(offerPriceData.dealEthAmount >= tranEthAmount, "Insufficient trading eth");
        require(offerPriceData.dealTokenAmount >= tranTokenAmount, "Insufficient trading token");
        require(offerPriceData.tokenAddress == tranTokenAddress, "Wrong token address");
        require(tranTokenAmount == offerPriceData.dealTokenAmount * tranEthAmount / offerPriceData.dealEthAmount, "Wrong token amount");
        
        // Update the offer information
        offerPriceData.ethAmount = offerPriceData.ethAmount.add(tranEthAmount);
        offerPriceData.tokenAmount = offerPriceData.tokenAmount.sub(tranTokenAmount);
        offerPriceData.dealEthAmount = offerPriceData.dealEthAmount.sub(tranEthAmount);
        offerPriceData.dealTokenAmount = offerPriceData.dealTokenAmount.sub(tranTokenAmount);
        _prices[index] = offerPriceData;
        // Create a new offer
        createOffer(ethAmount, tokenAmount, tranTokenAddress, isDeviate, 0);
        // Transfer in erc20 + offer asset to this contract
        if (tokenAmount > tranTokenAmount) {
            ERC20(tranTokenAddress).safeTransferFrom(address(msg.sender), address(this), tokenAmount.sub(tranTokenAmount));
        } else {
            ERC20(tranTokenAddress).safeTransfer(address(msg.sender), tranTokenAmount.sub(tokenAmount));
        }

        // Modify price
        _offerPrice.changePrice(tranEthAmount, tranTokenAmount, tranTokenAddress, offerPriceData.blockNum.add(_blockLimit));
        emit OfferTran(address(msg.sender), address(0x0), tranEthAmount, address(tranTokenAddress), tranTokenAmount, contractAddress, offerPriceData.owner);
        
        // Transfer fee
        if (serviceCharge > 0) {
            address nTokenAddress = _tokenMapping.checkTokenMapping(tranTokenAddress);
            _abonus.switchToEth.value(serviceCharge)(nTokenAddress);
        }
    }
    
    /**
    * @dev Taker order - pay erc20 and buy ETH
    * @param ethAmount The amount of ETH of this offer
    * @param tokenAmount The amount of erc20 of this offer
    * @param contractAddress The target offer address
    * @param tranEthAmount The amount of ETH of taker order
    * @param tranTokenAmount The amount of erc20 of taker order
    * @param tranTokenAddress The erc20 address of taker order
    */
    function sendErcBuyEth(uint256 ethAmount, uint256 tokenAmount, address contractAddress, uint256 tranEthAmount, uint256 tranTokenAmount, address tranTokenAddress) public payable {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        uint256 serviceCharge = tranEthAmount.mul(_tranEth).div(1000);
        require(msg.value == ethAmount.sub(tranEthAmount).add(serviceCharge), "msg.value needs to be equal to the quoted eth quantity plus transaction handling fee");
        require(tranEthAmount % _offerSpan == 0, "Transaction size does not meet asset span");
        //  Get the offer data structure
        uint256 index = toIndex(contractAddress);
        Nest_NToken_OfferPriceData memory offerPriceData = _prices[index]; 
        //  Check the price, compare the current offer to the last effective price
        bool thisDeviate = comparativePrice(ethAmount,tokenAmount,tranTokenAddress);
        bool isDeviate;
        if (offerPriceData.deviate == true) {
            isDeviate = true;
        } else {
            isDeviate = thisDeviate;
        }
        //  Limit the taker order only be twice the amount of the offer to prevent large-amount attacks
        if (offerPriceData.deviate) {
            //  The taker order deviates  x2
            require(ethAmount >= tranEthAmount.mul(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
        } else {
            if (isDeviate) {
                //  If the taken offer is normal and the taker order deviates x10
                require(ethAmount >= tranEthAmount.mul(_deviationFromScale), "EthAmount needs to be no less than 10 times of transaction scale");
            } else {
                //  If the taken offer is normal and the taker order is normal x2
                require(ethAmount >= tranEthAmount.mul(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
            }
        }
        // Check whether the conditions for taker order are satisfied
        require(checkContractState(offerPriceData.blockNum) == 0, "Offer status error");
        require(offerPriceData.dealEthAmount >= tranEthAmount, "Insufficient trading eth");
        require(offerPriceData.dealTokenAmount >= tranTokenAmount, "Insufficient trading token");
        require(offerPriceData.tokenAddress == tranTokenAddress, "Wrong token address");
        require(tranTokenAmount == offerPriceData.dealTokenAmount * tranEthAmount / offerPriceData.dealEthAmount, "Wrong token amount");
        // Update the offer information
        offerPriceData.ethAmount = offerPriceData.ethAmount.sub(tranEthAmount);
        offerPriceData.tokenAmount = offerPriceData.tokenAmount.add(tranTokenAmount);
        offerPriceData.dealEthAmount = offerPriceData.dealEthAmount.sub(tranEthAmount);
        offerPriceData.dealTokenAmount = offerPriceData.dealTokenAmount.sub(tranTokenAmount);
        _prices[index] = offerPriceData;
        // Create a new offer
        createOffer(ethAmount, tokenAmount, tranTokenAddress, isDeviate, 0);
        // Transfer in erc20 + offer asset to this contract
        ERC20(tranTokenAddress).safeTransferFrom(address(msg.sender), address(this), tranTokenAmount.add(tokenAmount));
        // Modify price
        _offerPrice.changePrice(tranEthAmount, tranTokenAmount, tranTokenAddress, offerPriceData.blockNum.add(_blockLimit));
        emit OfferTran(address(msg.sender), address(tranTokenAddress), tranTokenAmount, address(0x0), tranEthAmount, contractAddress, offerPriceData.owner);
        // Transfer fee
        if (serviceCharge > 0) {
            address nTokenAddress = _tokenMapping.checkTokenMapping(tranTokenAddress);
            _abonus.switchToEth.value(serviceCharge)(nTokenAddress);
        }
    }
    
    /**
     * Offering mining
     * @param ntoken NToken address
     **/
    function oreDrawing(address ntoken) private returns(uint256) {
        Nest_NToken miningToken = Nest_NToken(ntoken);
        (uint256 createBlock, uint256 recentlyUsedBlock) = miningToken.checkBlockInfo();
        uint256 attenuationPointNow = block.number.sub(createBlock).div(_blockAttenuation);
        uint256 miningAmount = 0;
        uint256 attenuation;
        if (attenuationPointNow > 9) {
            attenuation = _afterMiningAmount;
        } else {
            attenuation = _attenuationAmount[attenuationPointNow];
        }
        miningAmount = attenuation.mul(block.number.sub(recentlyUsedBlock));
        miningToken.increaseTotal(miningAmount);
        emit OreDrawingLog(block.number, miningAmount, ntoken);
        return miningAmount;
    }
    
    /**
     * Retrieve mining
     * @param token Token address
     **/
    function mining(uint256 blockNum, address token, uint256 serviceCharge, address owner) private returns(uint256) {
        //  Block mining amount*offer fee/block offer fee
        uint256 miningAmount = _blockMining[blockNum][token].mul(serviceCharge).div(_blockOfferAmount[blockNum][token]);        
        //  Transfer NToken 
        Nest_NToken nToken = Nest_NToken(address(_tokenMapping.checkTokenMapping(token)));
        require(nToken.transfer(address(owner), miningAmount), "Transfer failure");
        
        emit MiningLog(blockNum, token,_blockOfferAmount[blockNum][token]);
        return miningAmount;
    }
    
    // Compare order prices
    function comparativePrice(uint256 myEthValue, uint256 myTokenValue, address token) private view returns(bool) {
        (uint256 frontEthValue, uint256 frontTokenValue) = _offerPrice.updateAndCheckPricePrivate(token);
        if (frontEthValue == 0 || frontTokenValue == 0) {
            return false;
        }
        uint256 maxTokenAmount = myEthValue.mul(frontTokenValue).mul(uint256(100).add(_deviate)).div(frontEthValue.mul(100));
        if (myTokenValue <= maxTokenAmount) {
            uint256 minTokenAmount = myEthValue.mul(frontTokenValue).mul(uint256(100).sub(_deviate)).div(frontEthValue.mul(100));
            if (myTokenValue >= minTokenAmount) {
                return false;
            }
        }
        return true;
    }
    
    // Check contract status
    function checkContractState(uint256 createBlock) public view returns (uint256) {
        if (block.number.sub(createBlock) > _blockLimit) {
            return 1;
        }
        return 0;
    }
    
    // Transfer ETH
    function repayEth(address accountAddress, uint256 asset) private {
        address payable addr = accountAddress.make_payable();
        addr.transfer(asset);
    }
    
    // View the upper limit of the block interval
    function checkBlockLimit() public view returns(uint256) {
        return _blockLimit;
    }
    
    // View taker fee ratio
    function checkTranEth() public view returns (uint256) {
        return _tranEth;
    }
    
    // View additional transaction multiple
    function checkTranAddition() public view returns(uint256) {
        return _tranAddition;
    }
    
    // View minimum offering ETH
    function checkleastEth() public view returns(uint256) {
        return _leastEth;
    }
    
    // View offering ETH span
    function checkOfferSpan() public view returns(uint256) {
        return _offerSpan;
    }

    // View block offering amount
    function checkBlockOfferAmount(uint256 blockNum, address token) public view returns (uint256) {
        return _blockOfferAmount[blockNum][token];
    }
    
    // View offering block mining amount
    function checkBlockMining(uint256 blockNum, address token) public view returns (uint256) {
        return _blockMining[blockNum][token];
    }
    
    // View offering mining amount
    function checkOfferMining(uint256 blockNum, address token, uint256 serviceCharge) public view returns (uint256) {
        if (serviceCharge == 0) {
            return 0;
        } else {
            return _blockMining[blockNum][token].mul(serviceCharge).div(_blockOfferAmount[blockNum][token]);
        }
    }
    
    //  View the owner allocation ratio
    function checkOwnerMining() public view returns(uint256) {
        return _ownerMining;
    }
    
    // View the mining decay
    function checkAttenuationAmount(uint256 num) public view returns(uint256) {
        return _attenuationAmount[num];
    }
    
    // Modify taker order fee ratio
    function changeTranEth(uint256 num) public onlyOwner {
        _tranEth = num;
    }
    
    // Modify block interval upper limit
    function changeBlockLimit(uint32 num) public onlyOwner {
        _blockLimit = num;
    }
    
    // Modify additional transaction multiple
    function changeTranAddition(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _tranAddition = num;
    }
    
    // Modify minimum offering ETH
    function changeLeastEth(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _leastEth = num;
    }
    
    // Modify offering ETH span
    function changeOfferSpan(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _offerSpan = num;
    }
    
    // Modify price deviation
    function changekDeviate(uint256 num) public onlyOwner {
        _deviate = num;
    }
    
    // Modify the deviation from scale 
    function changeDeviationFromScale(uint256 num) public onlyOwner {
        _deviationFromScale = num;
    }
    
    // Modify the owner allocation ratio
    function changeOwnerMining(uint256 num) public onlyOwner {
        _ownerMining = num;
    }
    
    // Modify the mining decay
    function changeAttenuationAmount(uint256 firstAmount, uint256 top, uint256 bottom) public onlyOwner {
        uint256 blockAmount = firstAmount;
        for (uint256 i = 0; i < 10; i ++) {
            _attenuationAmount[i] = blockAmount;
            blockAmount = blockAmount.mul(top).div(bottom);
        }
    }
    
    // Vote administrators only
    modifier onlyOwner(){
        require(_voteFactory.checkOwners(msg.sender), "No authority");
        _;
    }
    
    /**
     * Get the number of offers stored in the offer array
     * @return The number of offers stored in the offer array
     **/
    function getPriceCount() view public returns (uint256) {
        return _prices.length;
    }
    
    /**
     * Get offer information according to the index
     * @param priceIndex Offer index
     * @return Offer information
     **/
    function getPrice(uint256 priceIndex) view public returns (string memory) {
        //  The buffer array used to generate the result string
        bytes memory buf = new bytes(500000);
        uint256 index = 0;
        index = writeOfferPriceData(priceIndex, _prices[priceIndex], buf, index);
        // Generate the result string and return
        bytes memory str = new bytes(index);
        while(index-- > 0) {
            str[index] = buf[index];
        }
        return string(str);
    }
    
    /**
     * Search the contract address list of the target account (reverse order)
     * @param start Search forward from the index corresponding to the given contract address (not including the record corresponding to start address)
     * @param count Maximum number of records to return
     * @param maxFindCount The max index to search
     * @param owner Target account address
     * @return Separate the offer records with symbols. use , to divide fields:  
     * uuid,owner,tokenAddress,ethAmount,tokenAmount,dealEthAmount,dealTokenAmount,blockNum,serviceCharge
     **/
    function find(address start, uint256 count, uint256 maxFindCount, address owner) view public returns (string memory) {
        // Buffer array used to generate result string
        bytes memory buf = new bytes(500000);
        uint256 index = 0;
        // Calculate search interval i and end
        uint256 i = _prices.length;
        uint256 end = 0;
        if (start != address(0)) {
            i = toIndex(start);
        }
        if (i > maxFindCount) {
            end = i - maxFindCount;
        }
        // Loop search, write qualified records into buffer
        while (count > 0 && i-- > end) {
            Nest_NToken_OfferPriceData memory price = _prices[i];
            if (price.owner == owner) {
                --count;
                index = writeOfferPriceData(i, price, buf, index);
            }
        }
        // Generate result string and return
        bytes memory str = new bytes(index);
        while(index-- > 0) {
            str[index] = buf[index];
        }
        return string(str);
    }
    
    /**
     * Get the list of offers by page
     * @param offset Skip the first offset records
     * @param count Maximum number of records to return
     * @param order Sort rules. 0 means reverse order, non-zero means positive order
     * @return Separate the offer records with symbols. use , to divide fields: 
     * uuid,owner,tokenAddress,ethAmount,tokenAmount,dealEthAmount,dealTokenAmount,blockNum,serviceCharge
     **/
    function list(uint256 offset, uint256 count, uint256 order) view public returns (string memory) {
        
        // Buffer array used to generate result string 
        bytes memory buf = new bytes(500000);
        uint256 index = 0;
        
        // Find search interval i and end
        uint256 i = 0;
        uint256 end = 0;
        
        if (order == 0) {
            // Reverse order, in default 
            // Calculate search interval i and end
            if (offset < _prices.length) {
                i = _prices.length - offset;
            } 
            if (count < i) {
                end = i - count;
            }
            
            // Write records in the target interval into the buffer
            while (i-- > end) {
                index = writeOfferPriceData(i, _prices[i], buf, index);
            }
        } else {
            // Ascending order
            // Calculate the search interval i and end
            if (offset < _prices.length) {
                i = offset;
            } else {
                i = _prices.length;
            }
            end = i + count;
            if(end > _prices.length) {
                end = _prices.length;
            }
            
            // Write the records in the target interval into the buffer
            while (i < end) {
                index = writeOfferPriceData(i, _prices[i], buf, index);
                ++i;
            }
        }
        
        // Generate the result string and return
        bytes memory str = new bytes(index);
        while(index-- > 0) {
            str[index] = buf[index];
        }
        return string(str);
    }   
     
    // Write the offer data into the buffer and return the buffer index
    function writeOfferPriceData(uint256 priceIndex, Nest_NToken_OfferPriceData memory price, bytes memory buf, uint256 index) pure private returns (uint256) {
        
        index = writeAddress(toAddress(priceIndex), buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeAddress(price.owner, buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeAddress(price.tokenAddress, buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeUInt(price.ethAmount, buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeUInt(price.tokenAmount, buf, index);
        buf[index++] = byte(uint8(44));
       
        index = writeUInt(price.dealEthAmount, buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeUInt(price.dealTokenAmount, buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeUInt(price.blockNum, buf, index);
        buf[index++] = byte(uint8(44));
        
        index = writeUInt(price.serviceCharge, buf, index);
        buf[index++] = byte(uint8(44));
        
        return index;
    }
     
    // Convert integer to string in decimal form, write the string into the buffer, and return the buffer index
    function writeUInt(uint256 iv, bytes memory buf, uint256 index) pure public returns (uint256) {
        uint256 i = index;
        do {
            buf[index++] = byte(uint8(iv % 10 +48));
            iv /= 10;
        } while (iv > 0);
        
        for (uint256 j = index; j > i; ++i) {
            byte t = buf[i];
            buf[i] = buf[--j];
            buf[j] = t;
        }
        
        return index;
    }

    // Convert the address to a hexadecimal string and write it into the buffer, and return the buffer index
    function writeAddress(address addr, bytes memory buf, uint256 index) pure private returns (uint256) {
        
        uint256 iv = uint256(addr);
        uint256 i = index + 40;
        do {
            uint256 w = iv % 16;
            if(w < 10) {
                buf[index++] = byte(uint8(w +48));
            } else {
                buf[index++] = byte(uint8(w +87));
            }
            
            iv /= 16;
        } while (index < i);
        
        i -= 40;
        for (uint256 j = index; j > i; ++i) {
            byte t = buf[i];
            buf[i] = buf[--j];
            buf[j] = t;
        }
        
        return index;
    }
}

// Price contract
interface Nest_3_OfferPrice {
    // Add price data
    function addPrice(uint256 ethAmount, uint256 tokenAmount, uint256 endBlock, address tokenAddress, address offerOwner) external;
    // Modify price
    function changePrice(uint256 ethAmount, uint256 tokenAmount, address tokenAddress, uint256 endBlock) external;
    function updateAndCheckPricePrivate(address tokenAddress) external view returns(uint256 ethAmount, uint256 erc20Amount);
}

// Voting contract
interface Nest_3_VoteFactory {
    //  Check address
	function checkAddress(string calldata name) external view returns (address contractAddress);
	// Check whether an administrator
	function checkOwners(address man) external view returns (bool);
}

// NToken contract
interface Nest_NToken {
    // Additional issuance
    function increaseTotal(uint256 value) external;
    // Check mining information
    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);
    // Check creator
    function checkBidder() external view returns(address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// NToken mapping contract
interface Nest_NToken_TokenMapping {
    // Check token mapping
    function checkTokenMapping(address token) external view returns (address);
}

// Bonus pool contract
interface Nest_3_Abonus {
    function switchToEth(address token) external payable;
    function switchToEthForNTokenOffer(address token) external payable;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
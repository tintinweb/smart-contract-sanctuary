pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC20Interface.sol";




contract Codainu  is ERC20Interface {
    using SafeMath for uint256;

                       event Burn(uint256 _value);

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 private _totalSupply;

    // Distribut percent -- 10%
    uint256 distributPercent = 10;

    // Controll address  tokens
    address private _contractControlAddress = 0x98618E74fE7326aE614D1FDa08813f18Cc03dD1a;

    // Developers addresses
    uint    private developerCount = 3;
    uint256 private tokensForOneDeveloper;
    uint256 private devTotalPercent = 5; // 5% total
    address private develop_address_1 = 0x3Fd184DCCe00b6E5E540FDbe1a0Ad89bDEF6b8f5;
    address private develop_address_2 = 0xB5B74ffc0C8F74D32dC17cE5d35676cE6CD133F1;
    address private develop_address_3 = 0x0cBC3B66F208727c6FB69ac557460B518e2421c3;


    // Marketing address
    uint256 private totalTokensForMarketing;
    uint256 private marketingTotalPercent = 5; // 5% total
    address private marketing_address = 0x4457362D94d9EcfAAfeE2AAF47C2b950a938a75c;
    // Map (send percent of total - time after tokens send to marketing address)
    mapping(uint => uint256) marketingTokensMap;

    // PreSale
    uint256 private maxPreSaleLimit = 500000000000000000000; // Limit 500 BNB
    uint256 private buyLimitForOneAddress = 1000000000000000000; // Limit 1 BNB
    uint256 private preSaleBnbBalance;
    mapping(address => uint256) preSaleLimitMap;
    // Array with all holders
    address[] public allTokenHolders;

    // Time
    uint256 private dayInMilliseconds = 86400;
    // uint256 private dayInMilliseconds = 2;

    // Burning
    address private burnAddress = address(this);
    uint256 private burnTotalSupply;
    uint256 private burnTotalPercent = 50; // 50% total burn
    uint256 private emmision; // total emmision

    // Map (burn percent - time after tokens burn)
    mapping(uint => uint256) burnTokensMap;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Koda Fun Token";
        symbol = "KOF";
        decimals = 18;
        _totalSupply = 1200000000000000000000000000000000;


        emmision = _totalSupply;
        burnTotalSupply = getQuantutyTokensByTotalAndPercent(_totalSupply,burnTotalPercent);

        // Send all tokens to smart contract address
        balances[burnAddress] = emmision;
        emit Transfer(address(0), burnAddress,emmision);

        // Send 5% tokens to developers accounts
        tokensForOneDeveloper = getQuantutyTokensByTotalAndPercent(emmision,devTotalPercent).div(developerCount);

        // 1 Developer send
        transferFromContranct(develop_address_1,tokensForOneDeveloper);
        addAddressToHoldArrayIfNotExist(develop_address_1);

        // 2 Developer send
        transferFromContranct(develop_address_2,tokensForOneDeveloper);
        addAddressToHoldArrayIfNotExist(develop_address_2);

        // 3 Developer send
        transferFromContranct(develop_address_3,tokensForOneDeveloper);
        addAddressToHoldArrayIfNotExist(develop_address_3);

        // send to Main address
        transferFromContranct(_contractControlAddress,46000000000000000000000000000000);
        addAddressToHoldArrayIfNotExist(_contractControlAddress);

        // Marketing
        // Total tokens for Marketing
        totalTokensForMarketing = getQuantutyTokensByTotalAndPercent(emmision,marketingTotalPercent);
        // First 15% tokens for Marketing
        uint256 firstSendTokensToMarketingAddress =  getQuantutyTokensByTotalAndPercent(totalTokensForMarketing,15);
        transferFromContranct(marketing_address,firstSendTokensToMarketingAddress);
        addAddressToHoldArrayIfNotExist(marketing_address);


        initialization();
    }



        function totalSupply() public view virtual override returns (uint) {
            return _totalSupply  - balances[address(0)];
        }

        function balanceOf(address tokenOwner) public view virtual override returns (uint balance) {
            return balances[tokenOwner];
        }

        function allowance(address tokenOwner, address spender) public view virtual override returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }

        function approve(address spender, uint tokens) public virtual override returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }

        function transfer(address to, uint tokens) ifNeedBurn() checkMarketingUnLock() public virtual override returns (bool success) {
            require(tokens >= 10, 'Error minimal distribute 10');

            uint256 _distributeFee = getQuantutyTokensByTotalAndPercent(tokens,distributPercent);

            balances[msg.sender] = balances[msg.sender].sub(tokens);
            distributeFee(tokens,msg.sender);

            // TODO add main address

            // Minus distribute Fee
            tokens = tokens.sub(_distributeFee);

            balances[to] = balances[to].add(tokens);

            emit Transfer(msg.sender, to, tokens);
            addAddressToHoldArrayIfNotExist(to);
            return true;
        }

        function transferFromContranct(address to, uint tokens)  private returns (bool success) {
            balances[address(this)] = balances[address(this)].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(address(this), to, tokens);
            return true;
        }

        function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success) {

            require(tokens >= 10, 'Error minimal distribute 10');

            uint256 _distributeFee = getQuantutyTokensByTotalAndPercent(tokens,distributPercent);

            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            distributeFee(tokens,from);

            // Minus distribute Fee
            tokens = tokens.sub(_distributeFee);

            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            addAddressToHoldArrayIfNotExist(to);
            return true;
        }

        // Percents var
        uint256 private percents_25 = 25;
        uint256 private percents_15 = 15;
        uint256 private percents_10 = 10;
        uint256 private percents_20 = 20;
        uint256 private percents_50 = 50;



        // Methods
        // Method for setting dates
        function initialization() private returns (bool success) {
            uint256 days_7 = 7;     // burn 25%
            uint256 days_30 = 30;   // burn 15%
            uint256 days_45 = 45;   // burn 10%
                                    // total 50%

            // Get the time of the first token burn after 7 days
            uint256 burnTime_1 = getTimeAddDays(days_7);

            // Get the time of the second token burn after 30 days
            uint256 burnTime_2 = getTimeAddDays(days_30);

            // Get the time of the third token burn after 45 days
            uint256 burnTime_3 = getTimeAddDays(days_45);

            // Init burn map
            burnTokensMap[percents_25] = burnTime_1;
            burnTokensMap[percents_15] = burnTime_2;
            burnTokensMap[percents_10] = burnTime_3;


            //   ======================     marketing
            uint256 days_40 = 40;
            uint256 months_3 = 90;
            uint256 months_6 = 180;


            // Get the time of the first token send after 40 days
            uint256 unLockMarketingTime_1 = getTimeAddDays(days_40);

            // Get the time of the first token send after 3 month
            uint256 unLockMarketingTime_2 = getTimeAddDays(months_3);

            // Get the time of the first token send after 6 month
            uint256 unLockMarketingTime_3 = getTimeAddDays(months_6);

            // Init unlock marketing map
            marketingTokensMap[percents_15] = unLockMarketingTime_1;
            marketingTokensMap[percents_20] = unLockMarketingTime_2;
            marketingTokensMap[percents_50] = unLockMarketingTime_3;

            return true;
        }

        modifier ifNeedBurn() {

            uint256  burnTime_1 =  burnTokensMap[percents_25];
            uint256  burnTime_2 =  burnTokensMap[percents_15];
            uint256  burnTime_3 =  burnTokensMap[percents_10];


            if(burnTokensMap[percents_25] != 0) {
                if (block.timestamp >= burnTime_1){
                    uint256 burnAmount = getQuantutyTokensByTotalAndPercent(emmision,percents_25);
                    burn(burnAmount);
                    delete burnTokensMap[percents_25];
                }
            }

            if(burnTokensMap[percents_15] != 0) {
                if (block.timestamp >= burnTime_2)  {
                    uint256 burnAmount = getQuantutyTokensByTotalAndPercent(emmision,percents_15);
                    burn(burnAmount);
                    delete burnTokensMap[percents_15];
                }
            }

            if(burnTokensMap[percents_10] != 0) {
                if (block.timestamp >= burnTime_3) {
                    uint256 burnAmount = getQuantutyTokensByTotalAndPercent(emmision,percents_10);
                    burn(burnAmount);
                    delete burnTokensMap[percents_10];
                }
            }

            _;
        }

        modifier checkMarketingUnLock() {

            uint256  unLockMarketingTime_1 =  marketingTokensMap[percents_15];
            uint256  unLockMarketingTime_2 =  marketingTokensMap[percents_20];
            uint256  unLockMarketingTime_3 =  marketingTokensMap[percents_50];




            if(marketingTokensMap[percents_15] != 0) {
                if (block.timestamp >= unLockMarketingTime_1){
                    uint256 sendAmount = getQuantutyTokensByTotalAndPercent(totalTokensForMarketing,percents_15);
                    balances[marketing_address] = balances[marketing_address].add(sendAmount);
                    emit Transfer(address(this), marketing_address,sendAmount);
                    delete marketingTokensMap[percents_15];
                }
            }

            if(marketingTokensMap[percents_20] != 0) {
                if (block.timestamp >= unLockMarketingTime_2){
                    uint256 sendAmount = getQuantutyTokensByTotalAndPercent(totalTokensForMarketing,percents_20);
                    balances[marketing_address] = balances[marketing_address].add(sendAmount);
                    emit Transfer(address(this), marketing_address,sendAmount);
                    delete marketingTokensMap[percents_20];
                }
            }

            if(marketingTokensMap[percents_50] != 0) {
                if (block.timestamp >= unLockMarketingTime_3){
                    uint256 sendAmount = getQuantutyTokensByTotalAndPercent(totalTokensForMarketing,percents_50);
                    balances[marketing_address] = balances[marketing_address].add(sendAmount);
                    emit Transfer(address(this), marketing_address,sendAmount);
                    delete marketingTokensMap[percents_50];
                }
            }



            _;
        }


        function getQuantutyTokensByTotalAndPercent(uint256 totalCount,uint256 percent) public pure returns (uint) {

            require(totalCount > 0,'Number zero');
            require(percent > 0 && percent <= 100 ,'Incorrect percent');

            return totalCount.mul(percent).div(100);
        }
        function getPercentByTotalAndQunatity(uint256 totalCount,uint256 quantity) public pure returns (uint) {
            require(totalCount > 0);
            require(totalCount > quantity);

            uint256 mul = quantity.mul(100);
            return mul.div(totalCount);
        }
        function getTimeAddDays(uint256 dayCount) public view returns (uint) {
            return  block.timestamp.add(dayInMilliseconds.mul(dayCount)) ;
        }

        function burn(uint256 _value) private returns (bool) {
            require(_value > 0,'Error count');

            balances[burnAddress] = balances[burnAddress].sub(_value);

            uint256 newBalance = _totalSupply.sub(_value);
            _totalSupply = newBalance;

            emit Transfer(burnAddress, address(0), _value);
            emit Burn(_value);
            return true;
        }

        function buy() public payable {
            // TODO add start and finish date
            // TODO add end limit

            require(maxPreSaleLimit >= preSaleBnbBalance,'Pre sale max bnb value');
            require(msg.value > 0,'The value must be greater than zero');
            require(msg.value <= buyLimitForOneAddress,'You can buy no more than 1 BNB');

            uint256 freeBuyTokens = getFreeLimitBuy(msg.sender);

            require(msg.value <= freeBuyTokens,'Buy limit error');

            uint256 sendTokens  = getTokenFromBnb(msg.value);
            transferFromContranct(msg.sender,sendTokens);

            addToLimitMapForPreSale(msg.sender,msg.value);
            addAddressToHoldArrayIfNotExist(msg.sender);
            preSaleBnbBalance = preSaleBnbBalance + msg.value;
        }


        modifier onlyOwner {
            require(msg.sender == _contractControlAddress, 'You address not owner');
            _;
        }

        function withdraw(address payable _to, uint _amount) onlyOwner public {
            _to.transfer(_amount);
        }

            /*
             Method for converting bnb to Koda tokens
            */
            function getTokenFromBnb(uint256 bnbWei) public  pure returns (uint256) {
                //  1 BNB = 40 000 000 000 Koda Inu  => 1 BNB Wei = 40000000000 Koda Wei
                return  bnbWei.mul(40000000000);
            }

            /*
             Get the bnb limit for which you can buy a token during the presale
            */
            function getFreeLimitBuy(address ownerAddress) private view returns (uint256) {
                return buyLimitForOneAddress.sub(preSaleLimitMap[ownerAddress]);
            }
            function getFreeLimitBuy() public view returns (uint256) {
                return buyLimitForOneAddress.sub(preSaleLimitMap[msg.sender]);
            }


            function addToLimitMapForPreSale(address ownerAddress,uint256 bnbWei) private {
                preSaleLimitMap[ownerAddress] = preSaleLimitMap[ownerAddress].add(bnbWei);
            }

                function distributeFee(uint256 feeAmount,address sender) private {
                    //   /**
                    //       10% transaction fees
                    //          4% liquidity
                    //           3% distribution
                    //              2% burn
                    //               1% marketing and promotion or charity goes to marketing wallet
                    //     */

                    uint256 liquidity = getQuantutyTokensByTotalAndPercent(feeAmount,4);
                    sendToContractAddress(liquidity,sender);

                    uint256 amount_burn = getQuantutyTokensByTotalAndPercent(feeAmount,2);
                    _burn(amount_burn,sender);

                    uint256 marketing = getQuantutyTokensByTotalAndPercent(feeAmount,1);
                    sendToMarketingAddress(marketing,sender);

                    uint256 rewards = getQuantutyTokensByTotalAndPercent(feeAmount,3);
                    splitBetweenHolders(rewards,sender);
                }


                    function sendToMarketingAddress(uint256 tokens,address fromAddress) private {
                        balances[marketing_address] = balances[marketing_address].add(tokens);
                        emit Transfer(fromAddress, marketing_address, tokens);
                    }
                        function sendToContractAddress(uint256 tokens,address fromAddress) private {
                            balances[address(this)] = balances[address(this)].add(tokens);
                            emit Transfer(fromAddress, address(this), tokens);
                        }
                            function _burn(uint256 tokens,address fromAddress) private {
                                uint256 newBalance = _totalSupply.sub(tokens);
                                _totalSupply = newBalance;
                                emit Transfer(fromAddress, address(0), tokens);
                            }
                                function sendToReawardAddress(uint256 tokens,address fromAddress,address to) private {
                                    balances[to] = balances[to].add(tokens);
                                    emit Transfer(fromAddress, to, tokens);
                                }

                                    function addAddressToHoldArrayIfNotExist(address holdAddress) private {
                                        for (uint256 i = 0; i < allTokenHolders.length; i++) {
                                            if(allTokenHolders[i] == holdAddress){
                                                return;
                                            }
                                        }
                                        allTokenHolders.push(holdAddress);
                                    }

                                        function splitBetweenHolders(uint256 tokens,address fromAddress) private {
                                            for (uint256 i = 0; i < allTokenHolders.length; i++) {
                                                //  /**
                                                //   *  Get the holder's balance
                                                //   **/
                                                uint addressBalance = balanceOf(allTokenHolders[i]);
                                                if (addressBalance == 0 ) continue;
                                                //  /**
                                                //   *  Get the holder's percentage of the total amount
                                                //   **/
                                                uint256 percentInTotal = getPercentByTotalAndQunatity(totalSupply(),addressBalance);
                                                if (percentInTotal == 0 ) continue;
                                                //  /**
                                                //   *  Convert the percentage of the reward to the number of tokens
                                                //   **/
                                                uint256 reward = getQuantutyTokensByTotalAndPercent(tokens,percentInTotal);
                                                //  /**
                                                //   *  Send reward to recipient
                                                //   **/
                                                sendToReawardAddress(reward,fromAddress,allTokenHolders[i]);
                                            }
                                        }




}
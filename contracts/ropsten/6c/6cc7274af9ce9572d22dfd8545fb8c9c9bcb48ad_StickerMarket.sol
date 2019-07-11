pragma solidity >=0.5.0 <0.6.0;

import "./SafeMath.sol";
import "./StickerPack.sol";
import "./StickerType.sol";
import "./ERC20Token.sol";
import "./ApproveAndCallFallBack.sol";
import "./Controlled.sol";
import "./TokenClaimer.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH) 
 * StickerMarket allows any address register "StickerPack" which can be sold to any address in form of "StickerPack", an ERC721 token.
 */
contract StickerMarket is Controlled, TokenClaimer, ApproveAndCallFallBack {
    using SafeMath for uint256;
    
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event MarketState(State state);
    event RegisterFee(uint256 value);
    event BurnRate(uint256 value);

    enum State { Invalid, Open, BuyOnly, Controlled, Closed }

    State public state = State.Open;
    uint256 registerFee;
    uint256 burnRate;
    
    //include global var to set burn rate/percentage
    ERC20Token public snt; //payment token
    StickerPack public stickerPack;
    StickerType public stickerType;
    
    /**
     * @dev can only be called when market is open or by controller on Controlled state
     */
    modifier marketManagement {
        require(state == State.Open || (msg.sender == controller && state == State.Controlled), "Market Disabled");
        _;
    }

    /**
     * @dev can only be called when market is open or buy-only state.
     */
    modifier marketSell {
        require(state == State.Open || state == State.BuyOnly || (msg.sender == controller && state == State.Controlled), "Market Disabled");
        _;
    }

    /**
     * @param _snt SNT token
     */
    constructor(
        ERC20Token _snt,
        StickerPack _stickerPack,
        StickerType _stickerType
    ) 
        public
    { 
        require(address(_snt) != address(0), "Bad _snt parameter");
        require(address(_stickerPack) != address(0), "Bad _stickerPack parameter");
        require(address(_stickerType) != address(0), "Bad _stickerType parameter");
        snt = _snt;
        stickerPack = _stickerPack;
        stickerType = _stickerType;
    }

    /** 
     * @dev Mints NFT StickerPack in `msg.sender` account, and Transfers SNT using user allowance
     * emit NonfungibleToken.Transfer(`address(0)`, `msg.sender`, `tokenId`)
     * @notice buy a pack from market pack owner, including a StickerPack&#39;s token in msg.sender account with same metadata of `_packId` 
     * @param _packId id of market pack 
     * @param _destination owner of token being brought
     * @param _price agreed price 
     * @return tokenId generated StickerPack token 
     */
    function buyToken(
        uint256 _packId,
        address _destination,
        uint256 _price
    ) 
        external  
        returns (uint256 tokenId)
    {
        return buy(msg.sender, _packId, _destination, _price);
    }

    /** 
     * @dev emits StickerMarket.Register(`packId`, `_urlHash`, `_price`, `_contenthash`)
     * @notice Registers to sell a sticker pack 
     * @param _price cost in wei to users minting this pack
     * @param _donate value between 0-10000 representing percentage of `_price` that is donated to StickerMarket at every buy
     * @param _category listing category
     * @param _owner address of the beneficiary of buys
     * @param _contenthash EIP1577 pack contenthash for listings
     * @param _fee Fee msg.sender agrees to pay for this registration
     * @return packId Market position of Sticker Pack data.
     */
    function registerPack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category, 
        address _owner,
        bytes calldata _contenthash,
        uint256 _fee
    ) 
        external  
        returns(uint256 packId)
    {
        packId = register(msg.sender, _category, _owner, _price, _donate, _contenthash, _fee);
    }

    /**
     * @notice MiniMeToken ApproveAndCallFallBack forwarder for registerPack and buyToken
     * @param _from account calling "approve and buy" 
     * @param _value must be exactly whats being consumed     
     * @param _token must be exactly SNT contract
     * @param _data abi encoded call 
     */
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _data
    ) 
        external 
    {
        require(_token == address(snt), "Bad token");
        require(_token == address(msg.sender), "Bad call");
        bytes4 sig = abiDecodeSig(_data);
        bytes memory cdata = slice(_data,4,_data.length-4);
        if(sig == this.buyToken.selector){
            require(cdata.length == 96, "Bad data length");
            (uint256 packId, address owner, uint256 price) = abi.decode(cdata, (uint256, address, uint256));
            require(_value == price, "Bad price value");
            buy(_from, packId, owner, price);
        } else if(sig == this.registerPack.selector) {
            require(cdata.length >= 188, "Bad data length");
            (uint256 price, uint256 donate, bytes4[] memory category, address owner, bytes memory contenthash, uint256 fee) = abi.decode(cdata, (uint256,uint256,bytes4[],address,bytes,uint256));
            require(_value == fee, "Bad fee value");
            register(_from, category, owner, price, donate, contenthash, fee);
        } else {
            revert("Bad call");
        }
    }

    /**
     * @notice changes market state, only controller can call.
     * @param _state new state
     */
    function setMarketState(State _state)
        external
        onlyController 
    {
        state = _state;
        emit MarketState(_state);
    }

    /**
     * @notice changes register fee, only controller can call.
     * @param _value total SNT cost of registration
     */
    function setRegisterFee(uint256 _value)
        external
        onlyController 
    {
        registerFee = _value;
        emit RegisterFee(_value);
    }

    /**
     * @notice changes burn rate percentage, only controller can call.
     * @param _value new value between 0 and 10000
     */
    function setBurnRate(uint256 _value)
        external
        onlyController 
    {
        burnRate = _value;
        require(_value <= 10000, "cannot be more then 100.00%");
        emit BurnRate(_value);
    }
    
    /** 
     * @notice controller can generate packs at will
     * @param _price cost in wei to users minting with _urlHash metadata
     * @param _donate optional amount of `_price` that is donated to StickerMarket at every buy
     * @param _category listing category
     * @param _owner address of the beneficiary of buys
     * @param _contenthash EIP1577 pack contenthash for listings
     * @return packId Market position of Sticker Pack data.
     */
    function generatePack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category, 
        address _owner,
        bytes calldata _contenthash
    ) 
        external  
        onlyController
        returns(uint256 packId)
    {
        packId = stickerType.generatePack(_price, _donate, _category, _owner, _contenthash);
    }

    /**
     * @notice removes all market data about a marketed pack, can only be called by market controller
     * @param _packId pack being purged
     * @param _limit limits categories being purged
     */
    function purgePack(uint256 _packId, uint256 _limit)
        external
        onlyController 
    {
        stickerType.purgePack(_packId, _limit);
    }

    /**
     * @notice controller can generate tokens at will
     * @param _owner account being included new token
     * @param _packId pack being minted
     * @return tokenId created
     */
    function generateToken(address _owner, uint256 _packId) 
        external
        onlyController 
        returns (uint256 tokenId)
    {
        return stickerPack.generateToken(_owner, _packId);
    }

    /**
     * @notice Change controller of stickerType
     * @param _newController new controller of stickerType.
     */
    function migrate(address payable _newController) 
        external
        onlyController 
    {
        require(_newController != address(0), "Cannot unset controller");
        stickerType.changeController(_newController);
        stickerPack.changeController(_newController);
    }

    /**
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token) 
        external
        onlyController 
    {
        withdrawBalance(_token, controller);
    }

    /**
     * @notice returns pack data of token
     * @param _tokenId user token being queried
     * @return categories, registration time and contenthash
     */
    function getTokenData(uint256 _tokenId) 
        external 
        view 
        returns (
            bytes4[] memory category,
            uint256 timestamp,
            bytes memory contenthash
        ) 
    {
        return stickerType.getPackSummary(stickerPack.tokenPackId(_tokenId));
    }

    /** 
     * @dev charges registerFee and register new pack to owner
     * @param _caller payment account
     * @param _category listing category
     * @param _owner address of the beneficiary of buys
     * @param _price cost in wei to users minting this pack
     * @param _donate value between 0-10000 representing percentage of `_price` that is donated to StickerMarket at every buy
     * @param _contenthash EIP1577 pack contenthash for listings
     * @param _fee Fee msg.sender agrees to pay for this registrion
     * @return created packId
     */
    function register(
        address _caller,
        bytes4[] memory _category,
        address _owner,
        uint256 _price,
        uint256 _donate,
        bytes memory _contenthash,
        uint256 _fee
    ) 
        internal 
        marketManagement
        returns(uint256 packId) 
    {
        require(_fee == registerFee, "Unexpected fee");
        if(registerFee > 0){
            require(snt.transferFrom(_caller, controller, registerFee), "Bad payment");
        }
        packId = stickerType.generatePack(_price, _donate, _category, _owner, _contenthash);
    }

    /** 
     * @dev transfer SNT from buyer to pack owner and mint sticker pack token 
     * @param _caller payment account
     * @param _packId id of market pack 
     * @param _destination owner of token being brought
     * @param _price agreed price 
     * @return created tokenId
     */
    function buy(
        address _caller,
        uint256 _packId,
        address _destination,
        uint256 _price
    ) 
        internal 
        marketSell
        returns (uint256 tokenId)
    {
        (
            address pack_owner,
            bool pack_mintable,
            uint256 pack_price,
            uint256 pack_donate
        ) = stickerType.getPaymentData(_packId);
        require(pack_owner != address(0), "Bad pack");
        require(pack_mintable, "Disabled");
        uint256 amount = pack_price;
        require(_price == amount, "Wrong price");
        require(amount > 0, "Unauthorized");
        if(amount > 0 && burnRate > 0) {
            uint256 burned = amount.mul(burnRate).div(10000);
            amount = amount.sub(burned);
            require(snt.transferFrom(_caller, Controlled(address(snt)).controller(), burned), "Bad burn");
        }
        if(amount > 0 && pack_donate > 0) {
            uint256 donate = amount.mul(pack_donate).div(10000);
            amount = amount.sub(donate);
            require(snt.transferFrom(_caller, controller, donate), "Bad donate");
        } 
        if(amount > 0) {
            require(snt.transferFrom(_caller, pack_owner, amount), "Bad payment");
        }
        return stickerPack.generateToken(_destination, _packId);
    }

    /**
     * @dev decodes sig of abi encoded call
     * @param _data abi encoded data
     * @return sig (first 4 bytes)
     */
    function abiDecodeSig(bytes memory _data) private pure returns(bytes4 sig){
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
        }
    }

    /**
     * @dev get a slice of byte array
     * @param _bytes source
     * @param _start pointer
     * @param _length size to read
     * @return sliced bytes
     */
    function slice(bytes memory _bytes, uint _start, uint _length) private pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don&#39;t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we&#39;re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin&#39;s length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let&#39;s just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }


    // For ABI/web3.js purposes
    // fired by StickerType
    event Register(uint256 indexed packId, uint256 dataPrice, bytes contenthash);
    // fired by StickerPack and MiniMeToken
      event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed value
    );
}
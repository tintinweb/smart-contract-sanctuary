pragma solidity >=0.5.0 <0.9.0;
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Stopable.sol";

/// @author 
/// @title Token contract
contract MixerTipToken is ERC20Detailed, ERC20Burnable, Stoppable {

    constructor (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint8 decimals
    ) ERC20Detailed(name, symbol, decimals)
    public {
        _mint(owner(), totalSupply * 10**uint(decimals));
    }

    // Don't accept ETH
    function () payable external {
        revert();
    }
    
    //------------------------
    // Lock account transfer 

    mapping (address => uint256) private _lockTimes;
    mapping (address => uint256) private _lockAmounts;

    event LockChanged(address indexed account, uint256 releaseTime, uint256 amount);

    /// Lock user amount.  (run only owner)
    /// @param account account to lock
    /// @param releaseTime Time to release from lock state.
    /// @param amount  amount to lock.
    /// @return Boolean
    function setLock(address account, uint256 releaseTime, uint256 amount) onlyOwner public {
        //require(now < releaseTime, "ERC20 : Current time is greater than release time");
        require(block.timestamp < releaseTime, "ERC20 : Current time is greater than release time");
        require(amount != 0, "ERC20: Amount error");
        _lockTimes[account] = releaseTime; 
        _lockAmounts[account] = amount;
        emit LockChanged( account, releaseTime, amount ); 
    }

    /// Get Lock information  (run anyone)
    /// @param account user acount
    /// @return lokced time and locked amount.
    function getLock(address account) public view returns (uint256 lockTime, uint256 lockAmount) {
        return (_lockTimes[account], _lockAmounts[account]);
    }

    /// Check lock state  (run anyone)
    /// @param account user acount
    /// @param amount amount to check.
    /// @return Boolean : Don't use balance (true)
    function _isLocked(address account, uint256 amount) internal view returns (bool) {
        return _lockAmounts[account] != 0 && 
            _lockTimes[account] > block.timestamp &&
            (
                balanceOf(account) <= _lockAmounts[account] ||
                balanceOf(account).sub(_lockAmounts[account]) < amount
            );
    }

    /// Transfer token  (run anyone)
    /// @param recipient Token trasfer destination acount.
    /// @param amount Token transfer amount.
    /// @return Boolean 
    function transfer(address recipient, uint256 amount) enabled public returns (bool) {
        require( !_isLocked( msg.sender, amount ) , "ERC20: Locked balance");
        return super.transfer(recipient, amount);
    }

    /// Transfer token  (run anyone)
    /// @param sender Token trasfer source acount.
    /// @param recipient Token transfer destination acount.
    /// @param amount Token transfer amount.
    /// @return Boolean 
    function transferFrom(address sender, address recipient, uint256 amount) enabled public returns (bool) {
        require( !_isLocked( sender, amount ) , "ERC20: Locked balance");
        return super.transferFrom(sender, recipient, amount);
    }

    /// Decrease token balance (run only owner)
    /// @param value Amount to decrease.
    function burn(uint256 value) onlyOwner public {
        require( !_isLocked( msg.sender, value ) , "ERC20: Locked balance");
        super.burn(value);
    }

    

    /// Mixers Ingredients
    struct Ingredient {
        string Name;
        uint64 registTime;
        uint256 Price;
        string Feature; // RGB
        uint256 GenIndex;
    }

    Ingredient[] ingredients;

    event ListingIngredient(string name, uint256 price);
    event BuyerIngredient(address Buyer, uint256 ingredientIdx, uint256 GenId, uint64 registTime);
    event MakeMixCocktail(address mixer, uint64 registTime);


    struct GenOfIngredient {
        uint256 gen0Ing;
        uint256 genidx;
    }
    
    
    // Index of Ingredient 
    mapping (address => uint[]) MyIngredients;
    // Gen Index of Ingredient 
    mapping (address => GenOfIngredient[] ) MyGenIngredients;

    // mapping (address => uint[]) BuyIngredientsMapping;
    mapping (uint256 => uint256) GenIngredientsLength;

    

    function getMyIngredientsLength() public view returns (uint) {
        return MyIngredients[msg.sender].length;
    }

    function getMyIngredientsId(uint index) public view returns (uint) {
        require(MyIngredients[msg.sender].length >= index, "Overflow Length");
        return MyIngredients[msg.sender][index];
    }


    function totalIngredients() public view returns (uint) {
        return ingredients.length - 1;
    }
    
    function Listing(string memory _igname, uint256 _igprice, string memory _Feature) public onlyOwner returns (uint){
        
        Ingredient memory _ingredients = Ingredient({Name: _igname,registTime: uint64(now),Price: _igprice,Feature: _Feature, GenIndex:0});
        uint256 newIngredientId = ingredients.push(_ingredients) - 1;
        
        require(newIngredientId == uint256(uint32(newIngredientId)));
        GenIngredientsLength[newIngredientId] = 0;
        emit ListingIngredient(_igname, _igprice);
        return newIngredientId;
    }

    function InformationOfIngredient (uint256 _idx) external view returns (
        string memory Name,
        uint256 number_of_owner,
        uint256 registTime,
        uint256 Price,
        string memory Feature
    ) {
        
        require( ingredients.length - 1 >= _idx, "No Exist yet");

        Ingredient storage ing = ingredients[_idx];

        Name = ing.Name;
        number_of_owner = ingredients[_idx].GenIndex;
        registTime = uint256(ing.registTime);
        Price = ing.Price;
        Feature = ing.Feature;
        
    }

    

    function BuyIngredient(uint256 _idx) public payable returns (
        string memory Name,
        uint256 Price,
        uint64 purchaseTime
    ){
        require( ingredients.length - 1 >= _idx, "No Exist yet");
        Ingredient storage ing = ingredients[_idx];
        uint256 oldPirce = ing.Price;
        
        require(balanceOf(msg.sender) >= ing.Price, "Not enough tokens in your wallet");

        // Check
        for(uint i=0; i< getMyIngredientsLength(); i++ ){
            if(getMyIngredientsId(i) == _idx){
                revert();
            }
        }
        
        
        allowance(msg.sender, msg.sender);
        approve(msg.sender, ing.Price);
        
        require(transfer(owner(), uint256(ing.Price)));
        
        // transfer old gen of Ingredient and new mint
        GenOfIngredient memory _goi = GenOfIngredient({gen0Ing:_idx,genidx:ingredients[_idx].GenIndex});
        MyGenIngredients[msg.sender].push(_goi);

        
        // event BuyerIngredient(address Buyer, uint256 ingredientIdx, uint256 GenId, uint64 registTime);
        emit BuyerIngredient(msg.sender, _idx, ingredients[_idx].GenIndex, uint64(now));

        MyIngredients[msg.sender].push(_idx);

        ingredients[_idx].Price = oldPirce + oldPirce * 1 / 100;
        ingredients[_idx].GenIndex += 1;
        GenIngredientsLength[_idx] = ingredients[_idx].GenIndex;
        
        Name = ing.Name;
        Price = ing.Price;
        purchaseTime = uint64(now);

    }


    // Owner MixCocktail Contests
    struct MixCocktail {
        // Owner
        address Mixer;
        bytes32 SuperReceipt;
        
        uint64 makeTime;// The timestamp from the block when this Cocktail came into existence.
        uint deadline;   // blocknumber
        
        // The Cocktail ingredient ID
        uint16 First_HexaIngredient; // must
        int16 Second_HexaIngredient; // have to
        int16 Third_HexaIngredient; // have to
        int16 Fourth_HexaIngredient; // have to
        int16 Fifth_HexaIngredient; // have to

        uint16 MixerIndex;
    }
    MixCocktail[] _mixCocktails;

    // Maker MixCocktail Contests
    struct MakersCocktail {
        // Owner
        address Mixer;
        bytes32 SuperReceipt;
        // The timestamp from the block when this Cocktail came into existence.
        uint64 makeTime;
        // The Cocktail Receipt, Hexadecimal of ingredient ID
        uint16 First_HexaIngredient;
        int16 Second_HexaIngredient;
        int16 Third_HexaIngredient;
        int16 Fourth_HexaIngredient;
        int16 Fifth_HexaIngredient;

    }
    MakersCocktail[] _makersCocktails;

    // Only Owner Start
    // if not use the ingredient int16 value is -1.
    function StartContest(uint16 _first, int16 _second, int16 _third, int16 _fourth, int16 _fifth) onlyOwner public returns (uint) {
        // uint256 MixIndexHash = uint256(keccak256(abi.encodePacked(block.difficulty, now, _first, _second, _third, _fourth, _fifth)));
        // MixCocktail memory mixCocktail = MixCocktail(
        //     {
        //         Mixer: owner(),
        //         SuperReceipt: bytes32(MixIndexHash),
        //         makeTime: uint64(now),
        //         deadline: block.number+201600, // BSC 3sec = 1block, 20 * 60min * 24hour * 7days
        //         First_HexaIngredient: _first,
        //         Second_HexaIngredient: _second,
        //         Third_HexaIngredient: _third,
        //         Fourth_HexaIngredient: _fourth,
        //         Fifth_HexaIngredient: _fifth,
        //         MixerIndex: uint16(MixIndexHash)
        //     }
        // );
        // uint256 newMixCocktailId = _mixCocktails.push(mixCocktail) - 1;
        
        // require(newMixCocktailId == uint256(uint32(newMixCocktailId)));
        // emit MakeMixCocktail(owner(), uint64(now));
        return OwnerMixMaker(_first, _second, _third, _fourth, _fifth);
        
    }

    function OwnerMixMaker(uint16 _first, int16 _second, int16 _third, int16 _fourth, int16 _fifth) private returns(uint){
        
        uint16 prevMixerIndex;

        if (_mixCocktails.length > 0){
            MixCocktail storage Contest = _mixCocktails[_mixCocktails.length - 1];
            prevMixerIndex = Contest.MixerIndex;
        }else{
            prevMixerIndex = uint16(block.difficulty);
        }

        uint256 MixIndexHash = uint256(keccak256(abi.encodePacked(prevMixerIndex, _first, _second, _third, _fourth, _fifth)));
        MakersCocktail memory _makersCocktail = MakersCocktail(
            {
                Mixer: msg.sender,
                SuperReceipt: bytes32(MixIndexHash),
                makeTime: uint64(now),
                First_HexaIngredient: _first,
                Second_HexaIngredient: _second,
                Third_HexaIngredient: _third,
                Fourth_HexaIngredient: _fourth,
                Fifth_HexaIngredient: _fifth
            }
        );
        uint256 newMixCocktailId = _makersCocktails.push(_makersCocktail) - 1;
        
        require(newMixCocktailId == uint256(uint32(newMixCocktailId)));
        emit MakeMixCocktail(owner(), uint64(now));
        return newMixCocktailId;
    }




    function StopContest(uint newMixCocktailId) onlyOwner public {
        require( _mixCocktails.length - 1 >= 0, "None");
        MixCocktail storage Contest = _mixCocktails[newMixCocktailId];
        Contest.deadline = block.number;
    }

    function RecentContest() public view returns (
        bytes32 SuperReceipt,
        uint64 StartTime,
        uint deadline,
        uint16 MixerIndex
    ){
        
        require( _mixCocktails.length - 1 >= 0, "None");
        MixCocktail storage Contest = _mixCocktails[_mixCocktails.length - 1];
        
        SuperReceipt = Contest.SuperReceipt;
        StartTime = uint64(Contest.makeTime);
        deadline = uint(Contest.deadline);
        MixerIndex = Contest.MixerIndex;
    }

    // Create NFT MixCocktail
    function makeCocktail(
        uint16 _first, int16 _second, int16 _third, int16 _fourth, int16 _fifth
    ) public returns(uint){
        // verify have ingredients
        bool buy_first_ing = false;
        bool buy_second_ing;
        bool buy_third_ing;
        bool buy_fourth_ing;
        bool buy_fifth_ing;
        
        if (_second < 0){
            buy_second_ing = true;
        }else{
            buy_second_ing = false;
        }

        if (_third < 0){
            buy_third_ing = true;
        }else{
            buy_third_ing = false;
        }

        if (_fourth < 0){
            buy_fourth_ing = true;
        }else{
            buy_fourth_ing = false;
        }

        if (_fifth < 0){
            buy_fifth_ing = true;
        }else{
            buy_fifth_ing = false;
        }
        
        for(uint i=0; i<MyGenIngredients[msg.sender].length; i++){

            GenOfIngredient memory _mgi = MyGenIngredients[msg.sender][i];
            if(_first == _mgi.gen0Ing){
                buy_first_ing = true;
            }

            if(buy_second_ing == false){
                if(_second > 0){
                    if(uint256(_second) == _mgi.gen0Ing){
                        buy_second_ing = true;
                    }
                }
                
            }

            if(buy_third_ing == false){
                if(_third > 0){
                    if(uint256(_third) == _mgi.gen0Ing){
                        buy_third_ing = true;
                    }
                }
            }

            if(buy_fourth_ing == false){
                if(_fourth>0){
                    if(uint256(_fourth) == _mgi.gen0Ing){
                        buy_fourth_ing = true;
                    }
                }
            }

            if(buy_fifth_ing == false){
                if(_fifth>0){
                    if(uint256(_fifth) == _mgi.gen0Ing){
                        buy_fifth_ing = true;
                    }
                }
            }
        }


        // Final Check
        require(buy_first_ing);
        require(buy_second_ing);
        require(buy_third_ing);
        require(buy_fourth_ing);
        require(buy_fifth_ing);

        // 
        MixCocktail storage Contest = _mixCocktails[_mixCocktails.length - 1];
        uint16 prevMixerIndex = Contest.MixerIndex;
        return MixMaker(prevMixerIndex, _first, _second, _third, _fourth, _fifth);

    }

    function MixMaker(uint16 prevMixerIndex, uint16 _first, int16 _second, int16 _third, int16 _fourth, int16 _fifth) private returns(uint){
        uint256 MixIndexHash = uint256(keccak256(abi.encodePacked(prevMixerIndex, _first, _second, _third, _fourth, _fifth)));
        MakersCocktail memory _makersCocktail = MakersCocktail(
            {
                Mixer: msg.sender,
                SuperReceipt: bytes32(MixIndexHash),
                makeTime: uint64(now),
                First_HexaIngredient: _first,
                Second_HexaIngredient: _second,
                Third_HexaIngredient: _third,
                Fourth_HexaIngredient: _fourth,
                Fifth_HexaIngredient: _fifth
            }
        );
        uint256 newMixCocktailId = _makersCocktails.push(_makersCocktail) - 1;
        
        require(newMixCocktailId == uint256(uint32(newMixCocktailId)));
        emit MakeMixCocktail(owner(), uint64(now));
        return newMixCocktailId;
    }

    // view NFT Cocktail
    function viewCocktail(uint makersCocktailId) public view returns (
        bytes32 SuperReceipt,
        address Mixer,
        uint64 makeTime,
        uint16 _first, int16 _second, int16 _third, int16 _fourth, int16 _fifth
    ){
        require(_makersCocktails.length - 1 >= 0, "None");
        
        MakersCocktail storage Cocktail = _makersCocktails[makersCocktailId];
        SuperReceipt = Cocktail.SuperReceipt;
        Mixer = Cocktail.Mixer;
        makeTime = Cocktail.makeTime;
        _first = Cocktail.First_HexaIngredient;
        _second = Cocktail.Second_HexaIngredient;
        _third = Cocktail.Third_HexaIngredient;
        _fourth = Cocktail.Fourth_HexaIngredient;
        _fifth = Cocktail.Fifth_HexaIngredient;
    }


}
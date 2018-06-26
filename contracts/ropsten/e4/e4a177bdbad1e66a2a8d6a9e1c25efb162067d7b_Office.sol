pragma solidity ^0.4.18;
pragma solidity ^0.4.18;

//
// Permissions
//
//                                      Owner    Renter   Anyone
// Initialize                             x
// Setup                                  x
// Set rental price                       x
// Make available/unavailable             x
// Force rental end (after period)        x
// Call function with onlyRenter                   x
// End rental before return time                   x
// Rent                                                      x

//

contract Rentable {

    // The owner of this object
    address public owner;
     // The account currently renting the object
    address public renter;

    // The date when the latest rental started
    uint public rentalDate;
    // The date when the latest rental is supposed to end
    uint public returnDate;

    // Whether or not the object is currently rented
    bool public rented;

    // The price per second of the rental (in wei)
    uint public rentalPrice;

    //Can not be rented for less time than this.
    //If renter tries to return the object earlier than this time, minimum will be charged anyways
    uint public minRentalTime;
    uint constant MIN_RENTAL_TIME = 60;

    //Can not be rented for longer than this.
    uint public maxRentalTime;
    uint constant MAX_RENTAL_TIME = 3600 * 24 * 365;

    // Whether or not the object can be rented. (Owner can take it off to prevent rental)
    // If its currently rented, making it unavailable doesn&#39;t stop it from being used
    bool public available;

    //
    // Events
    //

    event E_Rent(address indexed _renter, uint _rentalDate, uint _returnDate, uint _rentalPrice);
    event E_ReturnRental(address indexed _renter, uint _returnDate);

    //
    // MODIFIERS
    //

    /// @dev allows only the owner to call functions with this modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev allows only the current renter to call functions with this modifier
    modifier onlyRenter() {
        require(msg.sender == renter);
        _;
    }

    /// @dev allows functions with this modifier to be called only when NOT rented
    modifier whenNotRented() {
        require(!rented || now > returnDate);
        _;
    }

    /// @dev allows functions with this modifier to be called only when rented
    modifier whenRented() {
        require(rented && now <= returnDate);
        _;
    }

    /// @dev allows functions with this modifier to be called only when object is available
    modifier ifAvailable() {
        require(available);
        _;
    }

    /////////

    function Rentable() public {
        owner = msg.sender;
    }

    /// @dev sets up the rentable object
    /// @param _pricePerHour the rental price per hour in wei
    /// @param _minRentalTime the minimum time the object has to be rented for
    /// @param _maxRentalTime the maximum time the object has to be rented for
    function rentableSetup(uint _pricePerHour, uint _minRentalTime, uint _maxRentalTime) public onlyOwner {
        require(!available); // Take object down before trying to update
        require(_minRentalTime >= MIN_RENTAL_TIME &&
                _maxRentalTime <= MAX_RENTAL_TIME &&
                _minRentalTime < _maxRentalTime);

        available = true;
        minRentalTime = _minRentalTime;
        maxRentalTime = _maxRentalTime;

        setRentalPricePerHour(_pricePerHour); // _pricePerHour > 0;

    }

    ///@dev owner can make the object available/unavailable for rental
    function setAvailable(bool _available) public onlyOwner {
        available = _available;
    }

    function setRentalPricePerHour(uint _pricePerHour) public onlyOwner whenNotRented{
        require(_pricePerHour > 0);
        rentalPrice = _pricePerHour / 3600;
    }

    function setRentalPricePerDay(uint _pricePerDay) public onlyOwner whenNotRented{
        require(_pricePerDay > 0);
        rentalPrice = _pricePerDay / 24 / 3600;
    }

    function setRentalPricePerSecond(uint _pricePerSecond) public onlyOwner whenNotRented{
        require(_pricePerSecond > 0);
        rentalPrice = _pricePerSecond;
    }

    /// @dev rents the object for any given time depending money sent and price of object
    function rent() public payable ifAvailable whenNotRented{
        require (msg.value > 0);
        require (rentalPrice > 0);              // Make sure the rental price was set

        uint rentalTime = msg.value / rentalPrice;
        require(rentalTime >= minRentalTime && rentalTime <= maxRentalTime);

        returnDate = now + rentalTime;

        rented = true;
        renter = msg.sender;
        rentalDate = now;

        E_Rent(renter, rentalDate, returnDate, rentalPrice);
    }

    /// @return the elapsed time since the object was rented
    function rentalElapsedTime() public view whenRented returns (uint){
        return now - rentalDate;
    }

    /// @return the wei owed by the renter given how much time has passed since the rental
    function rentalAccumulatedPrice() public view whenRented returns (uint){
        uint _rentalElapsedTime = rentalElapsedTime();
        return rentalPrice * _rentalElapsedTime;
    }

    function rentalBalanceRemaining() public view whenRented returns (uint){
        return rentalTimeRemaining() * rentalPrice;
    }

    function rentalTimeRemaining() public view whenRented returns (uint){
        return (returnDate - now);
    }

    function rentalTotalTime() public view whenRented returns (uint){
        return (returnDate - rentalDate);
    }


    /// @dev can be called by owner of the object if renter doesn&#39;t return it.
    function forceRentalEnd() public onlyOwner{
        require(now > returnDate && rented);

        E_ReturnRental(renter, now);

        resetRental();
    }

    /// @dev the renter can return the object during the rental period and get a refund of the outstanding time
    function returnRental() public onlyRenter whenRented {
        // Calculate rental remaining time and return money to renter
        // If time elapsed is less than the minimum rental time, we charge the minimum
        // Else, we return all pending balance.
        uint fundsToReturn = 0;
        if(rentalElapsedTime() < minRentalTime){
            fundsToReturn = (rentalTotalTime() - minRentalTime) * rentalPrice ;
        }else{
            fundsToReturn = rentalBalanceRemaining();
        }

        E_ReturnRental(renter, now);

        resetRental();

        msg.sender.transfer(fundsToReturn);


    }

    /// @dev resets the rental variables
    function resetRental() private{
        rented = false;
        renter = address(0);
        rentalDate = 0;
        returnDate = 0;
    }

}

contract Office is Rentable {

    string public name;
    string public typee;
    uint public duration;
    uint public timesUsed;

    function Office(string _name, string _typee, uint _duration) public
    {
        name = _name;
        typee = _typee;
        duration = _duration;
        timesUsed = 0;
    }

    function RentOffice() public onlyRenter whenRented returns(bool){
        timesUsed++;
        return true;
    }
}
//Constructor takes array of timestamps which indicate the end of time interval with fixed rate, and array of rates
contract TimedRateContract {

    uint[] public timestamps; //indicates the end of the interval
    uint[] public rates; //rate[i] is for time before timestamps[i]

    constructor(uint[] memory _timestamps, uint[] memory _rates) public {
        require(_timestamps.length>1); //if the tim
        require(_timestamps.length == _rates.length);
        for (uint i=0; i<_timestamps.length-1; i++) {
            require(_timestamps[i+1] > _timestamps[i]);//check if timestamps are greater one another
        }
        timestamps = _timestamps;
        rates = _rates;
    }
    
    function howManyTokens(uint _amount, address _contributor) public view returns(uint) {
        for (uint i=0; i<rates.length; i++) {
            if (now < timestamps[i]) {
                return rates[i]*_amount;
            }
        }
        return rates[rates.length-1]*_amount;
    }

}
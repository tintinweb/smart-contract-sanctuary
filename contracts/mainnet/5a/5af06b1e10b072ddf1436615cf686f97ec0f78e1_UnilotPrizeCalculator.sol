pragma solidity ^0.4.16;


contract UnilotPrizeCalculator {
    //Calculation constants
    uint64  constant accuracy                   = 1000000000000000000;
    uint8  constant MAX_X_FOR_Y                = 195;  // 19.5

    uint8  constant minPrizeCoeficent          = 1;
    uint8  constant percentOfWinners           = 5;    // 5%
    uint8  constant percentOfFixedPrizeWinners = 20;   // 20%

    uint8  constant gameCommision              = 0;   // 0%
    uint8  constant bonusGameCommision         = 0;   // 0%
    uint8  constant tokenHolerGameCommision    = 0;    // 0%
    // End Calculation constants

    event Debug(uint);

    function getPrizeAmount(uint totalAmount)
        public
        pure
        returns (uint result)
    {
        uint totalCommision = gameCommision
                            + bonusGameCommision
                            + tokenHolerGameCommision;

        //Calculation is odd on purpose.  It is a sort of ceiling effect to
        // maximize amount of prize
        result = ( totalAmount - ( ( totalAmount * totalCommision) / 100) );

        return result;
    }

    function getNumWinners(uint numPlayers)
        public
        pure
        returns (uint16 numWinners, uint16 numFixedAmountWinners)
    {
        // Calculation is odd on purpose. It is a sort of ceiling effect to
        // maximize number of winners
        uint16 totaNumlWinners = uint16( numPlayers - ( (numPlayers * ( 100 - percentOfWinners ) ) / 100 ) );


        numFixedAmountWinners = uint16( (totaNumlWinners * percentOfFixedPrizeWinners) / 100 );
        numWinners = uint16( totaNumlWinners - numFixedAmountWinners );

        return (numWinners, numFixedAmountWinners);
    }

    function calcaultePrizes(uint bet, uint numPlayers)
        public
        pure
        returns (uint[50] memory prizes)
    {
        var (numWinners, numFixedAmountWinners) = getNumWinners(numPlayers);

        require( uint(numWinners + numFixedAmountWinners) <= prizes.length );

        uint[] memory y = new uint[]((numWinners - 1));
        uint z = 0; // Sum of all Y values

        if ( numWinners == 1 ) {
            prizes[0] = getPrizeAmount(uint(bet*numPlayers));

            return prizes;
        } else if ( numWinners < 1 ) {
            return prizes;
        }

        for (uint i = 0; i < y.length; i++) {
            y[i] = formula( (calculateStep(numWinners) * i) );
            z += y[i];
        }

        bool stop = false;

        for (i = 0; i < 10; i++) {
            uint[5] memory chunk = distributePrizeCalculation(
                i, z, y, numPlayers, bet);

            for ( uint j = 0; j < chunk.length; j++ ) {
                if ( ( (i * chunk.length) + j ) >= ( numWinners + numFixedAmountWinners ) ) {
                    stop = true;
                    break;
                }

                prizes[ (i * chunk.length) + j ] = chunk[j];
            }

            if ( stop ) {
                break;
            }
        }

        return prizes;
    }

    function distributePrizeCalculation (uint chunkNumber, uint z, uint[] memory y, uint totalNumPlayers, uint bet)
        private
        pure
        returns (uint[5] memory prizes)
    {
        var(numWinners, numFixedAmountWinners) = getNumWinners(totalNumPlayers);
        uint prizeAmountForDeligation = getPrizeAmount( (totalNumPlayers * bet) );
        prizeAmountForDeligation -= uint( ( bet * minPrizeCoeficent ) * uint( numWinners + numFixedAmountWinners ) );

        uint mainWinnerBaseAmount = ( (prizeAmountForDeligation * accuracy) / ( ( ( z * accuracy ) / ( 2 * y[0] ) ) + ( 1 * accuracy ) ) );
        uint undeligatedAmount    = prizeAmountForDeligation;

        uint startPoint = chunkNumber * prizes.length;

        for ( uint i = 0; i < prizes.length; i++ ) {
            if ( i >= uint(numWinners + numFixedAmountWinners) ) {
                break;
            }
            prizes[ i ] = (bet * minPrizeCoeficent);
            uint extraPrize = 0;

            if ( i == ( numWinners - 1 ) ) {
                extraPrize = undeligatedAmount;
            } else if ( i == 0 && chunkNumber == 0 ) {
                extraPrize = mainWinnerBaseAmount;
            } else if ( ( startPoint + i ) < numWinners ) {
                extraPrize = ( ( y[ ( startPoint + i ) - 1 ] * (prizeAmountForDeligation - mainWinnerBaseAmount) ) / z);
            }

            prizes[ i ] += extraPrize;
            undeligatedAmount -= extraPrize;
        }

        return prizes;
    }

    function formula(uint x)
        public
        pure
        returns (uint y)
    {
        y = ( (1 * accuracy**2) / (x + (5*accuracy/10))) - ((5 * accuracy) / 100);

        return y;
    }

    function calculateStep(uint numWinners)
        public
        pure
        returns(uint step)
    {
        step = ( MAX_X_FOR_Y * accuracy / 10 ) / numWinners;

        return step;
    }
}
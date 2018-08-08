pragma solidity ^0.4.11;

//
// ==== DISCLAIMER ====
//
// ETHEREUM IS STILL AN EXPEREMENTAL TECHNOLOGY.
// ALTHOUGH THIS SMART CONTRACT WAS CREATED WITH GREAT CARE AND IN THE HOPE OF BEING USEFUL, NO GUARANTEES OF FLAWLESS OPERATION CAN BE GIVEN.
// IN PARTICULAR - SUBTILE BUGS, HACKER ATTACKS OR MALFUNCTION OF UNDERLYING TECHNOLOGY CAN CAUSE UNINTENTIONAL BEHAVIOUR.
// YOU ARE STRONGLY ENCOURAGED TO STUDY THIS SMART CONTRACT CAREFULLY IN ORDER TO UNDERSTAND POSSIBLE EDGE CASES AND RISKS.
// DON&#39;T USE THIS SMART CONTRACT IF YOU HAVE SUBSTANTIAL DOUBTS OR IF YOU DON&#39;T KNOW WHAT YOU ARE DOING.
//
// THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
// OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ====
//
//
// ==== PARANOIA NOTICE ====
// A careful reader will find some additional checks and excessive code, consuming some extra gas. This is intentional.
// Even though the contract should work without these parts, they make the code more secure in production and for future refactoring.
// Also, they show more clearly what we have considered and addressed during development.
// Discussion is welcome!
// ====
//

/// @author written by ethernian for Santiment Sagl
/// @notice report bugs to: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9dffe8faeeddf8e9f5f8eff3f4fcf3b3fef2f0">[email&#160;protected]</a>
/// @title Santiment WhiteList contract
contract SantimentWhiteList {

    string constant public VERSION = "0.3.0";

    function () { throw; }   //explicitly unpayable

    struct Limit {
        uint24 min;  //finney
        uint24 max;  //finney
    }

    struct LimitWithAddr {
        address addr;
        uint24 min; //finney
        uint24 max; //finney
    }

    mapping(address=>Limit) public allowed;
    uint16  public chunkNr = 0;
    uint    public recordNum = 0;
    uint256 public controlSum = 0;
    bool public isSetupMode = true;
    address public admin;

    function SantimentWhiteList() { admin = msg.sender; }

    ///@dev add next address package to the internal white list.
    ///@dev call is allowed in setup mode only.
    function addPack(address[] addrs, uint24[] mins, uint24[] maxs, uint16 _chunkNr)
    setupOnly
    adminOnly
    external {
        var len = addrs.length;
        require ( chunkNr++ == _chunkNr);
        require ( mins.length == len &&  mins.length == len );
        for(uint16 i=0; i<len; ++i) {
            var addr = addrs[i];
            var max  = maxs[i];
            var min  = mins[i];
            Limit lim = allowed[addr];
            //remove old record if exists
            if (lim.max > 0) {
                controlSum -= uint160(addr) + lim.min + lim.max;
                delete allowed[addr];
            }
            //insert record if max > 0
            if (max > 0) {
                // max > 0 means add a new record into the list.
                allowed[addr] = Limit({min:min, max:max});
                controlSum += uint160(addr) + min + max;
            }
        }//for
        recordNum+=len;
    }

    ///@dev disable setup mode
    function start()
    adminOnly
    public {
        isSetupMode = false;
    }

    modifier setupOnly {
        if ( !isSetupMode ) throw;
        _;
    }

    modifier adminOnly {
        if (msg.sender != admin) throw;
        _;
    }

    //=== for better debug ====
    function ping()
    adminOnly
    public {
        log("pong");
    }
    event log(string);

}
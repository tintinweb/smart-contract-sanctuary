/**
 *Submitted for verification at polygonscan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Skills";
    string constant public class = "Any";

    function skill_by_id(uint _id) external pure returns(
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        if (_id == 1) {
            return appraise();
        } else if (_id == 2) {
            return balance();
        } else if (_id == 3) {
            return bluff();
        } else if (_id == 4) {
            return climb();
        } else if (_id == 5) {
            return concentration();
        } else if (_id == 6) {
            return craft();
        } else if (_id == 7) {
            return decipher_script();
        } else if (_id == 8) {
            return diplomacy();
        } else if (_id == 9) {
            return disable_device();
        } else if (_id == 10) {
            return disguise();
        } else if (_id == 11) {
            return escape_artist();
        } else if (_id == 12) {
            return forgery();
        } else if (_id == 13) {
            return gather_information();
        } else if (_id == 14) {
            return handle_animal();
        } else if (_id == 15) {
            return heal();
        } else if (_id == 16) {
            return hide();
        } else if (_id == 17) {
            return intimidate();
        } else if (_id == 18) {
            return jump();
        } else if (_id == 19) {
            return knowledge();
        } else if (_id == 20) {
            return listen();
        } else if (_id == 21) {
            return move_silently();
        } else if (_id == 22) {
            return open_lock();
        } else if (_id == 23) {
            return perform();
        } else if (_id == 24) {
            return profession();
        } else if (_id == 25) {
            return ride();
        } else if (_id == 26) {
            return search();
        } else if (_id == 27) {
            return sense_motive();
        } else if (_id == 28) {
            return sleight_of_hand();
        } else if (_id == 29) {
            return speak_language();
        } else if (_id == 30) {
            return spellcraft();
        } else if (_id == 31) {
            return spot();
        } else if (_id == 32) {
            return survival();
        } else if (_id == 33) {
            return swim();
        } else if (_id == 34) {
            return tumble();
        } else if (_id == 35) {
            return use_magic_device();
        } else if (_id == 36) {
            return use_rope();
        }
    }

    function get_attribute(uint id) external pure returns (string memory attribute) {
        if (id == 1) {
            return "Strength";
        } else if (id == 2) {
            return "Dexterity";
        } else if (id == 3) {
            return "Constitution";
        } else if (id == 4) {
            return "Intelligence";
        } else if (id == 5) {
            return "Wisdom";
        } else if (id == 6) {
            return "Charisma";
        }
    }

    function appraise() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 1;
        name = "Appraise";
        attribute_id = 4;
        synergy = 6; // craft
        retry = false;
        armor_check_penalty = false;
        check = "You can appraise common or well-known objects with a DC 12 Appraise check. Failure means that you estimate the value at 50% to 150% (2d6+3 times 10%,) of its actual value. Appraising a rare or exotic item requires a successful check against DC 15, 20, or higher. If the check is successful, you estimate the value correctly; failure means you cannot estimate the items value.";
        action = "Appraising an item takes 1 minute (ten consecutive full-round actions).";
    }

    function balance() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 2;
        name = "Balance";
        attribute_id = 2;
        synergy = 34; // tumble
        retry = false;
        armor_check_penalty = true;
        check = "You can walk on a precarious surface. A successful check lets you move at half your speed along the surface for 1 round. A failure by 4 or less means you cant move for 1 round. A failure by 5 or more means you fall. The difficulty varies with the surface, as follows:";
        action = "None. A Balance check doesnt require an action; it is made as part of another action or as a reaction to a situation.";
    }

    function bluff() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 3;
        name = "Bluff";
        attribute_id = 6;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "A Bluff check is opposed by the targets Sense Motive check. See the accompanying table for examples of different kinds of bluffs and the modifier to the targets Sense Motive check for each one.";
        action = "Varies. A Bluff check made as part of general interaction always takes at least 1 round (and is at least a full-round action), but it can take much longer if you try something elaborate.";
    }

    function climb() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 4;
        name = "Climb";
        attribute_id = 1;
        synergy = 36; // use rope
        retry = true;
        armor_check_penalty = true;
        check = "With a successful Climb check, you can advance up, down, or across a slope, a wall, or some other steep incline (or even a ceiling with handholds) at one-quarter your normal speed. A slope is considered to be any incline at an angle measuring less than 60 degrees; a wall is any incline at an angle measuring 60 degrees or more.";
        action = "Climbing is part of movement, so its generally part of a move action (and may be combined with other types of movement in a move action).";
    }

    function concentration() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 5;
        name = "Concentration";
        attribute_id = 3;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You must make a Concentration check whenever you might potentially be distracted (by taking damage, by harsh weather, and so on) while engaged in some action that requires your full attention. Such actions include casting a spell, concentrating on an active spell, directing a spell, using a spell-like ability, or using a skill that would provoke an attack of opportunity. In general, if an action wouldnt normally provoke an attack of opportunity, you need not make a Concentration check to avoid being distracted.";
        action = "None. Making a Concentration check doesnt take an action; it is either a free action (when attempted reactively) or part of another action (when attempted actively).";
    }

    function craft() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 6;
        name = "Craft";
        attribute_id = 4;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You can practice your trade and make a decent living, earning about half your check result in gold pieces per week of dedicated work. You know how to use the tools of your trade, how to perform the crafts daily tasks, how to supervise untrained helpers, and how to handle common problems. (Untrained laborers and assistants earn an average of 1 silver piece per day.)";
        action = "Does not apply. Craft checks are made by the day or week (see above).";
    }

    function decipher_script() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 7;
        name = "Decipher Script";
        attribute_id = 4;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "You can decipher writing in an unfamiliar language or a message written in an incomplete or archaic form. The base DC is 20 for the simplest messages, 25 for standard texts, and 30 or higher for intricate, exotic, or very old writing.";
        action = "Deciphering the equivalent of a single page of script takes 1 minute (ten consecutive full-round actions).";
    }

    function diplomacy() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 8;
        name = "Diplomacy";
        attribute_id = 6;
        synergy = 3; // bluff
        retry = false;
        armor_check_penalty = false;
        check = "You can change the attitudes of others (nonplayer characters) with a successful Diplomacy check; see the Influencing NPC Attitudes sidebar, below, for basic DCs. In negotiations, participants roll opposed Diplomacy checks, and the winner gains the advantage. Opposed checks also resolve situations when two advocates or diplomats plead opposite cases in a hearing before a third party.";
        action = "Changing others attitudes with Diplomacy generally takes at least 1 full minute (10 consecutive full-round actions). In some situations, this time requirement may greatly increase. A rushed Diplomacy check can be made as a full-round action, but you take a -10 penalty on the check.";
    }

    function disable_device() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 9;
        name = "Disable Device";
        attribute_id = 4;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "The Disable Device check is made secretly, so that you dont necessarily know whether youve succeeded. The DC depends on how tricky the device is. Disabling (or rigging or jamming) a fairly simple device has a DC of 10; more intricate and complex devices have higher DCs.";
        action = "The amount of time needed to make a Disable Device check depends on the task, as noted above. Disabling a simple device takes 1 round and is a full-round action. An intricate or complex device requires 1d4 or 2d4 rounds.";
    }

    function disguise() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 10;
        name = "Disguise";
        attribute_id = 6;
        synergy = 3; // bluff
        retry = true;
        armor_check_penalty = false;
        check = "Your Disguise check result determines how good the disguise is, and it is opposed by others Spot check results. If you dont draw any attention to yourself, others do not get to make Spot checks. If you come to the attention of people who are suspicious (such as a guard who is watching commoners walking through a city gate), it can be assumed that such observers are taking 10 on their Spot checks.";
        action = "Creating a disguise requires 1d3*10 minutes of work.";
    }

    function escape_artist() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 11;
        name = "Escape Artist";
        attribute_id = 2;
        synergy = 36; // use rope
        retry = true;
        armor_check_penalty = true;
        check = "Your Escape Artist check is opposed by the binders Use Rope check. Since its easier to tie someone up than to escape from being tied up, the binder gets a +10 bonus on his or her check.";
        action = "Making an Escape Artist check to escape from rope bindings, manacles, or other restraints (except a grappler) requires 1 minute of work. Escaping from a net or an animate rope, command plants, control plants, or entangle spell is a full-round action. Escaping from a grapple or pin is a standard action. Squeezing through a tight space takes at least 1 minute, maybe longer, depending on how long the space is.";
    }

    function forgery() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 12;
        name = "Forgery";
        attribute_id = 4;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "Forgery requires writing materials appropriate to the document being forged, enough light or sufficient visual acuity to see the details of what youre writing, wax for seals (if appropriate), and some time. To forge a document on which the handwriting is not specific to a person (military orders, a government decree, a business ledger, or the like), you need only to have seen a similar document before, and you gain a +8 bonus on your check. To forge a signature, you need an autograph of that person to copy, and you gain a +4 bonus on the check. To forge a longer document written in the hand of some particular person, a large sample of that persons handwriting is needed.";
        action = "Forging a very short and simple document takes about 1 minute. A longer or more complex document takes 1d4 minutes per page.";
    }

    function gather_information() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 13;
        name = "Gather Information";
        attribute_id = 6;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "An evenings time, a few gold pieces for buying drinks and making friends, and a DC 10 Gather Information check get you a general idea of a citys major news items, assuming there are no obvious reasons why the information would be withheld. The higher your check result, the better the information.";
        action = "A typical Gather Information check takes 1d4+1 hours.";
    }

    function handle_animal() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 14;
        name = "Handle Animal";
        attribute_id = 6;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "This task involves commanding an animal to perform a task or trick that it knows. If the animal is wounded or has taken any nonlethal damage or ability score damage, the DC increases by 2. If your check succeeds, the animal performs the task or trick on its next action.";
        action = "Varies. Handling an animal is a move action.";
    }

    function heal() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 15;
        name = "Heal";
        attribute_id = 5;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You usually use first aid to save a dying character. If a character has negative hit points and is losing hit points (at the rate of 1 per round, 1 per hour, or 1 per day), you can make him or her stable. A stable character regains no hit points but stops losing them.";
        action = "Providing first aid, treating a wound, or treating poison is a standard action.";
    }

    function hide() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 16;
        name = "Hide";
        attribute_id = 2;
        synergy = 0;
        retry = false;
        armor_check_penalty = true;
        check = "Your Hide check is opposed by the Spot check of anyone who might see you. You can move up to one-half your normal speed and hide at no penalty. When moving at a speed greater than one-half but less than your normal speed, you take a -5 penalty. Its practically impossible (-20 penalty) to hide while attacking, running or charging.";
        action = "Usually none. Normally, you make a Hide check as part of movement, so it doesnt take a separate action.";
    }

    function intimidate() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 17;
        name = "Intimidate";
        attribute_id = 6;
        synergy = 3; // bluff
        retry = true;
        armor_check_penalty = false;
        check = "You can change anothers behavior with a successful check. Your Intimidate check is opposed by the targets modified level check (1d20 + character level or Hit Dice + targets Wisdom bonus [if any] + targets modifiers on saves against fear). If you beat your targets check result, you may treat the target as friendly, but only for the purpose of actions taken while it remains intimidated. (That is, the target retains its normal attitude, but will chat, advise, offer limited help, or advocate on your behalf while intimidated. See the Diplomacy skill, above, for additional details.) The effect lasts as long as the target remains in your presence, and for 1d6*10 minutes afterward. After this time, the targets default attitude toward you shifts to unfriendly (or, if normally unfriendly, to hostile).";
        action = "Varies. Changing anothers behavior requires 1 minute of interaction. Intimidating an opponent in combat is a standard action.";
    }

    function jump() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 18;
        name = "Jump";
        attribute_id = 1;
        synergy = 34; // tumble
        retry = true;
        armor_check_penalty = true;
        check = "The DC and the distance you can cover vary according to the type of jump you are attempting (see below). Your Jump check is modified by your speed. If your speed is 30 feet then no modifier based on speed applies to the check. If your speed is less than 30 feet, you take a -6 penalty for every 10 feet of speed less than 30 feet. If your speed is greater than 30 feet, you gain a +4 bonus for every 10 feet beyond 30 feet. All Jump DCs given here assume that you get a running start, which requires that you move at least 20 feet in a straight line before attempting the jump. If you do not get a running start, the DC for the jump is doubled. Distance moved by jumping is counted against your normal maximum movement in a round. If you have ranks in Jump and you succeed on a Jump check, you land on your feet (when appropriate). If you attempt a Jump check untrained, you land prone unless you beat the DC by 5 or more.";
        action = "None. A Jump check is included in your movement, so it is part of a move action.";
    }

    function knowledge() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 19;
        name = "Knowledge";
        attribute_id = 4;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "Answering a question within your field of study has a DC of 10 (for really easy questions), 15 (for basic questions), or 20 to 30 (for really tough questions). In many cases, you can use this skill to identify monsters and their special powers or vulnerabilities. In general, the DC of such a check equals 10 + the monsters HD. A successful check allows you to remember a bit of useful information about that monster. For every 5 points by which your check result exceeds the DC, you recall another piece of useful information.";
        action = "Usually none. In most cases, making a Knowledge check doesnt take an action-you simply know the answer or you dont.";
    }

    function listen() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 20;
        name = "Listen";
        attribute_id = 5;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "Your Listen check is either made against a DC that reflects how quiet the noise is that you might hear, or it is opposed by your targets Move Silently check. In the case of people trying to be quiet, the DCs given on the table could be replaced by Move Silently checks, in which case the indicated DC would be their average check result.";
        action = "Varies. Every time you have a chance to hear something in a reactive manner (such as when someone makes a noise or you move into a new area), you can make a Listen check without using an action. Trying to hear something you failed to hear previously is a move action.";
    }

    function move_silently() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 21;
        name = "Move Silently";
        attribute_id = 2;
        synergy = 0;
        retry = true;
        armor_check_penalty = true;
        check = "Your Move Silently check is opposed by the Listen check of anyone who might hear you. You can move up to one-half your normal speed at no penalty. When moving at a speed greater than one-half but less than your full speed, you take a -5 penalty. Its practically impossible (-20 penalty) to move silently while running or charging. Noisy surfaces, such as bogs or undergrowth, are tough to move silently across. When you try to sneak across such a surface, you take a penalty on your Move Silently check as indicated below.";
        action = "None. A Move Silently check is included in your movement or other activity, so it is part of another action.";
    }

    function open_lock() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 22;
        name = "Open Lock";
        attribute_id = 2;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "The DC for opening a lock varies from 20 to 40, depending on the quality of the lock, as given on the table below.";
        action = "Opening a lock is a full-round action.";
    }

    function perform() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 23;
        name = "Perform";
        attribute_id = 6;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You can impress audiences with your talent and skill.";
        action = "Varies. Trying to earn money by playing in public requires anywhere from an evenings work to a full days performance.";
    }

    function profession() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 24;
        name = "Profession";
        attribute_id = 5;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You can practice your trade and make a decent living, earning about half your Profession check result in gold pieces per week of dedicated work. You know how to use the tools of your trade, how to perform the professions daily tasks, how to supervise helpers, and how to handle common problems.";
        action = "Not applicable. A single check generally represents a week of work.";
    }

    function ride() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 25;
        name = "Ride";
        attribute_id = 2;
        synergy = 14; // handle animal
        retry = true;
        armor_check_penalty = false;
        check = "Typical riding actions dont require checks. You can saddle, mount, ride, and dismount from a mount without a problem.";
        action = "Varies. Mounting or dismounting normally is a move action. Other checks are a move action, a free action, or no action at all, as noted above.";
    }

    function search() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 26;
        name = "Search";
        attribute_id = 4;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You generally must be within 10 feet of the object or surface to be searched. The table below gives DCs for typical tasks involving the Search skill.";
        action = "It takes a full-round action to search a 5-foot-by-5-foot area or a volume of goods 5 feet on a side.";
    }

    function sense_motive() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 27;
        name = "Sense Motive";
        attribute_id = 5;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "A successful check lets you avoid being bluffed. You can also use this skill to determine when 'something is up' (that is, something odd is going on) or to assess someones trustworthiness.";
        action = "Trying to gain information with Sense Motive generally takes at least 1 minute, and you could spend a whole evening trying to get a sense of the people around you.";
    }

    function sleight_of_hand() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 28;
        name = "Sleight Of Hand";
        attribute_id = 2;
        synergy = 3; // bluff
        retry = false;
        armor_check_penalty = true;
        check = "A DC 10 Sleight of Hand check lets you palm a coin-sized, unattended object. Performing a minor feat of legerdemain, such as making a coin disappear, also has a DC of 10 unless an observer is determined to note where the item went.";
        action = "Any Sleight of Hand check normally is a standard action. However, you may perform a Sleight of Hand check as a free action by taking a -20 penalty on the check.";
    }

    function speak_language() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 29;
        name = "Speak Language";
        attribute_id = 0;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "Not applicable.";
        action = "Not applicable.";
    }

    function spellcraft() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 30;
        name = "Spellcraft";
        attribute_id = 4;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "You can identify spells and magic effects. The DCs for Spellcraft checks relating to various tasks are summarized on the table below.";
        action = "Varies.";
    }

    function spot() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 31;
        name = "Spot";
        attribute_id = 5;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "The Spot skill is used primarily to detect characters or creatures who are hiding. Typically, your Spot check is opposed by the Hide check of the creature trying not to be seen. Sometimes a creature isnt intentionally hiding but is still difficult to see, so a successful Spot check is necessary to notice it. A Spot check result higher than 20 generally lets you become aware of an invisible creature near you, though you cant actually see it.";
        action = "Varies. Every time you have a chance to spot something in a reactive manner you can make a Spot check without using an action.";
    }

    function survival() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 32;
        name = "Survival";
        attribute_id = 5;
        synergy = 0;
        retry = false;
        armor_check_penalty = false;
        check = "You can keep yourself and others safe and fed in the wild. The table below gives the DCs for various tasks that require Survival checks.";
        action = "Varies. For getting along in the wild or for gaining the Fortitude save bonus noted in the table above, you make a Survival check once every 24 hours.";
    }

    function swim() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 33;
        name = "Swim";
        attribute_id = 1;
        synergy = 0;
        retry = false;
        armor_check_penalty = true;
        check = "Make a Swim check once per round while you are in the water. Success means you may swim at up to one-half your speed (as a full-round action) or at one-quarter your speed (as a move action). If you fail by 4 or less, you make no progress through the water. If you fail by 5 or more, you go underwater.";
        action = "A successful Swim check allows you to swim one-quarter of your speed as a move action or one-half your speed as a full-round action.";
    }

    function tumble() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 34;
        name = "Tumble";
        attribute_id = 2;
        synergy = 18; // jump
        retry = false;
        armor_check_penalty = true;
        check = "You can land softly when you fall or tumble past opponents. You can also tumble to entertain an audience (as though using the Perform skill). The DCs for various tasks involving the Tumble skill are given on the table below.";
        action = "Not applicable. Tumbling is part of movement, so a Tumble check is part of a move action.";
    }

    function use_magic_device() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 35;
        name = "Use Magic Device";
        attribute_id = 6;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "You can use this skill to read a spell or to activate a magic item. Use Magic Device lets you use a magic item as if you had the spell ability or class features of another class, as if you were a different race, or as if you were of a different alignment. You make a Use Magic Device check each time you activate a device such as a wand. If you are using the check to emulate an alignment or some other quality in an ongoing manner, you need to make the relevant Use Magic Device check once per hour.";
        action = "None. The Use Magic Device check is made as part of the action (if any) required to activate the magic item.";
    }

    function use_rope() public pure returns (
        uint id,
        string memory name,
        uint attribute_id,
        uint synergy,
        bool retry,
        bool armor_check_penalty,
        string memory check,
        string memory action
    ) {
        id = 36;
        name = "Use Rope";
        attribute_id = 2;
        synergy = 0;
        retry = true;
        armor_check_penalty = false;
        check = "Securing a grappling hook requires a Use Rope check (DC 10, +2 for every 10 feet of distance the grappling hook is thrown, to a maximum DC of 20 at 50 feet). Failure by 4 or less indicates that the hook fails to catch and falls, allowing you to try again. Failure by 5 or more indicates that the grappling hook initially holds, but comes loose after 1d4 rounds of supporting weight. This check is made secretly, so that you dont know whether the rope will hold your weight.";
        action = "Varies. Throwing a grappling hook is a standard action that provokes an attack of opportunity.";
    }
}
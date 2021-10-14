/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//技能
contract codex {
    string constant public index = "Skills";
    string constant public class = "Any";

    //id技能
    function skill_by_id(uint _id) external pure returns(
        uint id,
        string memory name,
        uint attribute_id,//属性 ID
        uint synergy,//协同作用
        bool retry,//重试
        bool armor_check_penalty,//装甲检查惩罚
        string memory check,//检查
        string memory action//行动
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
    
    //获取属性
    function get_attribute(uint id) external pure returns (string memory attribute) {
        if (id == 1) {
            return "Strength";//力量
        } else if (id == 2) {
            return "Dexterity";//灵巧
        } else if (id == 3) {
            return "Constitution";//宪法
        } else if (id == 4) {
            return "Intelligence";//智力
        } else if (id == 5) {
            return "Wisdom";//智慧
        } else if (id == 6) {
            return "Charisma";//魅力
        }
    }
    
    //估价
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
        //你可以通过 DC 12 的评估检定来评估常见或知名的物体。 失败意味着您估计该值是其实际值的 50% 到 150%（2d6+3 乘以 10%）。 评估稀有或奇异物品需要成功通过 DC 15、20 或更高的检定。 如果检查成功，则您正确估计了该值； 失败意味着您无法估计物品的价值。
        check = "You can appraise common or well-known objects with a DC 12 Appraise check. Failure means that you estimate the value at 50% to 150% (2d6+3 times 10%,) of its actual value. Appraising a rare or exotic item requires a successful check against DC 15, 20, or higher. If the check is successful, you estimate the value correctly; failure means you cannot estimate the items value.";
        //估价一个物品需要 1 分钟（连续十次整轮动作）
        action = "Appraising an item takes 1 minute (ten consecutive full-round actions).";
    }

    //平衡感
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
        //"你可以在不稳定的表面上行走。成功的检定可以让你以一半的速度沿着表面移动 1 轮。失败 4 或更少意味着你不能移动 1 轮。失败 5 或更多意味着你 掉落。难度因地而异，如下：";
        check = "You can walk on a precarious surface. A successful check lets you move at half your speed along the surface for 1 round. A failure by 4 or less means you cant move for 1 round. A failure by 5 or more means you fall. The difficulty varies with the surface, as follows:";
        //Nona 余额检查不需要任何操作； 它是作为另一个动作的一部分或作为对某种情况的反应而做出的。
        action = "None. A Balance check doesnt require an action; it is made as part of another action or as a reaction to a situation.";
    }
    
    //唬骗
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
        //"唬骗检定与目标的察言观色检定相反。请参阅附表，了解不同类型的诈唬的例子，以及针对每一种诈唬的目标感觉动机检定的修正。";
        check = "A Bluff check is opposed by the targets Sense Motive check. See the accompanying table for examples of different kinds of bluffs and the modifier to the targets Sense Motive check for each one.";
        //"因人而异。作为一般互动的一部分进行的唬骗检定总是至少需要 1 轮（并且至少是一个整轮动作），但如果你尝试一些复杂的事情，它可能需要更长的时间。";
        action = "Varies. A Bluff check made as part of general interaction always takes at least 1 round (and is at least a full-round action), but it can take much longer if you try something elaborate.";
    }
    //攀爬
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
        //"通过成功的攀爬检定，您可以以正常速度的四分之一向上、向下或越过斜坡、墙壁或其他一些陡峭的斜坡（甚至带有扶手的天花板）。斜坡被认为是 角度小于 60 度的任何倾斜；墙壁是任何角度为 60 度或更大的倾斜。”；
        check = "With a successful Climb check, you can advance up, down, or across a slope, a wall, or some other steep incline (or even a ceiling with handholds) at one-quarter your normal speed. A slope is considered to be any incline at an angle measuring less than 60 degrees; a wall is any incline at an angle measuring 60 degrees or more.";
        //"攀爬是运动的一部分，所以它通常是移动动作的一部分（并且可能与移动动作中的其他类型的移动相结合）。";
        action = "Climbing is part of movement, so its generally part of a move action (and may be combined with other types of movement in a move action).";
    }
    
    //专注
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
        //"当你在进行一些需要你全神贯注的动作时，只要你可能会分心（受到伤害、恶劣天气等），你就必须进行一次专注力检查。这些动作包括施放法术、专注于一个活跃的 法术、指挥法术、使用类法术能力或使用会引发借机攻击的技能。一般来说，如果一个动作通常不会引发借机攻击，你就不需要进行专注检定以避免分心 .";
        check = "You must make a Concentration check whenever you might potentially be distracted (by taking damage, by harsh weather, and so on) while engaged in some action that requires your full attention. Such actions include casting a spell, concentrating on an active spell, directing a spell, using a spell-like ability, or using a skill that would provoke an attack of opportunity. In general, if an action wouldnt normally provoke an attack of opportunity, you need not make a Concentration check to avoid being distracted.";
        //"无。进行专注力检定不会采取行动；它要么是一个自由行动（当被动尝试时），要么是另一个动作的一部分（当主动尝试时）。”;
        action = "None. Making a Concentration check doesnt take an action; it is either a free action (when attempted reactively) or part of another action (when attempted actively).";
    }
    
    //工艺
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
        //"你可以练习你的交易并过上体面的生活，每周通过专注工作赚取大约一半的支票结果金币。你知道如何使用你的交易工具，如何执行手工艺日常任务，如何 监督未经培训的帮手，以及如何处理常见问题。（未经培训的工人和助手每天平均赚取1银币。）”；
        check = "You can practice your trade and make a decent living, earning about half your check result in gold pieces per week of dedicated work. You know how to use the tools of your trade, how to perform the crafts daily tasks, how to supervise untrained helpers, and how to handle common problems. (Untrained laborers and assistants earn an average of 1 silver piece per day.)";
        //"不适用。工艺检查按天或按周进行（见上文）。";
        action = "Does not apply. Craft checks are made by the day or week (see above).";
    }

    //文件解读
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
        //"你可以破译用不熟悉的语言书写的文字，或者以不完整或过时的形式书写的信息。最简单的信息的基础 DC 是 20，标准文本的基础 DC 是 25，复杂的、异国的或非常古老的文字是 30 或更高 .";
        check = "You can decipher writing in an unfamiliar language or a message written in an incomplete or archaic form. The base DC is 20 for the simplest messages, 25 for standard texts, and 30 or higher for intricate, exotic, or very old writing.";
        //"破译相当于一页脚本需要 1 分钟（十个连续的整轮动作）。";
        action = "Deciphering the equivalent of a single page of script takes 1 minute (ten consecutive full-round actions).";
    }
    
    //交涉
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
        //"你可以通过一次成功的外交检定来改变其他人（非玩家角色）的态度；参见下面的影响 NPC 态度边栏，了解基本 DC。在谈判中，参与者投反对派外交检定，胜利者获得优势。反对 当两名辩护人或外交官在第三方听证会上提出相反的案件时，检查也可以解决这种情况。”；
        check = "You can change the attitudes of others (nonplayer characters) with a successful Diplomacy check; see the Influencing NPC Attitudes sidebar, below, for basic DCs. In negotiations, participants roll opposed Diplomacy checks, and the winner gains the advantage. Opposed checks also resolve situations when two advocates or diplomats plead opposite cases in a hearing before a third party.";
        //"用交涉改变他人态度一般至少需要1整分钟（连续10个整轮动作）。在某些情况下，这个时间要求可能会大大增加。匆忙的交涉检定可以作为一个整轮动作进行，但是 你在支票上受到-10的惩罚。”;
        action = "Changing others attitudes with Diplomacy generally takes at least 1 full minute (10 consecutive full-round actions). In some situations, this time requirement may greatly increase. A rushed Diplomacy check can be made as a full-round action, but you take a -10 penalty on the check.";
    }

    //解除装置
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
        //"禁用设备检查是秘密进行的，因此您不一定知道是否成功。DC 取决于设备的复杂程度。禁用（或操纵或干扰）一个相当简单的设备的 DC 为 10；更复杂 和复杂的设备具有更高的 DC。”;
        check = "The Disable Device check is made secretly, so that you dont necessarily know whether youve succeeded. The DC depends on how tricky the device is. Disabling (or rigging or jamming) a fairly simple device has a DC of 10; more intricate and complex devices have higher DCs.";
        //"进行禁用设备检查所需的时间取决于任务，如上所述。禁用一个简单的设备需要 1 轮，并且是一个整轮动作。复杂或复杂的设备需要 1d4 或 2d4 轮。 ;
        action = "The amount of time needed to make a Disable Device check depends on the task, as noted above. Disabling a simple device takes 1 round and is a full-round action. An intricate or complex device requires 1d4 or 2d4 rounds.";
    }

    //易容
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
        //"你的伪装检查结果决定了伪装的好坏，它会被别人的抽查结果反对。如果你不引起自己的注意，别人就不会进行抽查。如果你引起人们的注意 谁是可疑的（例如正在观察穿过城门的平民的守卫），可以假设这些观察者在他们的抽查中取了 10。”;
        check = "Your Disguise check result determines how good the disguise is, and it is opposed by others Spot check results. If you dont draw any attention to yourself, others do not get to make Spot checks. If you come to the attention of people who are suspicious (such as a guard who is watching commoners walking through a city gate), it can be assumed that such observers are taking 10 on their Spot checks.";
        //"创建一个伪装需要 1d3*10 分钟的工作。";
        action = "Creating a disguise requires 1d3*10 minutes of work.";
    }
    
    //脱逃
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
        //你的脱逃者检定与活页夹使用绳索检定相反。因为绑住某人比摆脱被绑更容易，活页夹在他或她的检定上获得+10加值。";
        check = "Your Escape Artist check is opposed by the binders Use Rope check. Since its easier to tie someone up than to escape from being tied up, the binder gets a +10 bonus on his or her check.";
        //"进行脱逃检查以摆脱绳索束缚、手铐或其他束缚（抓钩器除外）需要 1 分钟的工作。从网或有生命的绳索、指挥植物、控制植物或缠结法术中逃脱是一个 ";
        action = "Making an Escape Artist check to escape from rope bindings, manacles, or other restraints (except a grappler) requires 1 minute of work. Escaping from a net or an animate rope, command plants, control plants, or entangle spell is a full-round action. Escaping from a grapple or pin is a standard action. Squeezing through a tight space takes at least 1 minute, maybe longer, depending on how long the space is.";
    }

    //伪造文书
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
        //"伪造需要适合被伪造文件的书写材料、足够的光线或足够的视力来查看您所写内容的细节、封印蜡（如果适用）以及一些时间。伪造一份手写的文件 不特定于某个人（军事命令、政府法令、商业分类帐等），您只需要之前看过类似的文件，您的支票就会获得 +8 加值。要伪造签名，您 需要该人的亲笔签名进行复制，并且您在该检查上获得 +4 加值。要伪造由某个特定人手写的较长文件，需要大量该人的笔迹样本。”;
        check = "Forgery requires writing materials appropriate to the document being forged, enough light or sufficient visual acuity to see the details of what youre writing, wax for seals (if appropriate), and some time. To forge a document on which the handwriting is not specific to a person (military orders, a government decree, a business ledger, or the like), you need only to have seen a similar document before, and you gain a +8 bonus on your check. To forge a signature, you need an autograph of that person to copy, and you gain a +4 bonus on the check. To forge a longer document written in the hand of some particular person, a large sample of that persons handwriting is needed.";
        //"伪造一个非常短而简单的文档大约需要 1 分钟。更长或更复杂的文档每页需要 1d4 分钟。";
        action = "Forging a very short and simple document takes about 1 minute. A longer or more complex document takes 1d4 minutes per page.";
    }

    //收集信息
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
        //"一个晚上的时间，买酒和交朋友的几块金币，以及 DC 10 收集信息检查让你对一个城市的主要新闻项目有一个大致的了解，假设没有明显的原因可以隐瞒信息。 检查结果越高，信息越好。";
        check = "An evenings time, a few gold pieces for buying drinks and making friends, and a DC 10 Gather Information check get you a general idea of a citys major news items, assuming there are no obvious reasons why the information would be withheld. The higher your check result, the better the information.";
        //"一次典型的收集信息检查需要 1d4+1 小时。";
        action = "A typical Gather Information check takes 1d4+1 hours.";
    }

    //驯养动物
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
        //"此任务涉及命令动物执行它知道的任务或技巧。如果动物受伤或受到任何非致命伤害或属性值伤害，则 DC 增加 2。如果您的检查成功，动物执行 下一步行动的任务或技巧。”;
        check = "This task involves commanding an animal to perform a task or trick that it knows. If the animal is wounded or has taken any nonlethal damage or ability score damage, the DC increases by 2. If your check succeeds, the animal performs the task or trick on its next action.";
        //"因人而异。处理动物是一个移动动作。";
        action = "Varies. Handling an animal is a move action.";
    }

    //医疗
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
        //"你通常使用急救来拯救一个垂死的角色。如果一个角色的生命值为负并且正在失去生命值（以每轮 1、每小时 1 或每天 1 的速度），你可以让他或 她的马厩。稳定的角色不会恢复生命值，但不会失去生命值。”;
        check = "You usually use first aid to save a dying character. If a character has negative hit points and is losing hit points (at the rate of 1 per round, 1 per hour, or 1 per day), you can make him or her stable. A stable character regains no hit points but stops losing them.";
        //"提供急救、治疗伤口或治疗毒药是一个标准动作。";
        action = "Providing first aid, treating a wound, or treating poison is a standard action.";
    }

    //躲藏
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
        //"你的躲藏检定与可能看到你的任何人的侦察检定相反。你可以以正常速度的二分之一移动并且躲藏不受惩罚。当移动速度大于二分之一但小于你的速度时 正常速度，你会受到-5的惩罚。在攻击、奔跑或冲锋时几乎不可能隐藏（-20惩罚）。”;
        check = "Your Hide check is opposed by the Spot check of anyone who might see you. You can move up to one-half your normal speed and hide at no penalty. When moving at a speed greater than one-half but less than your normal speed, you take a -5 penalty. Its practically impossible (-20 penalty) to hide while attacking, running or charging.";
        //"通常没有。通常，你做一个隐藏检定作为移动的一部分，所以它不会采取单独的行动。";
        action = "Usually none. Normally, you make a Hide check as part of movement, so it doesnt take a separate action.";
    }

    //威吓
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
        //"你可以通过成功的检定改变他人的行为。你的威吓检定与目标修改等级检定相反（1d20 + 角色等级或生命骰子 + 目标感知加值 [如果有] + 目标对抗恐惧豁免时的修正）。如果 你击败了你的目标检查结果，你可以将目标视为友好，但仅限于在它仍然受到威胁时采取的行动。（即目标保持其正常态度，但会聊天，建议，提供有限的帮助，或 在被恐吓时为你代言。更多细节参见上面的交涉技能。）只要目标留在你面前，效果就会持续，之后持续 1d6*10 分钟。在此时间之后，目标对你的默认态度 转变为不友好（或者，如果通常不友好，则转变为敌对）。”；
        check = "You can change anothers behavior with a successful check. Your Intimidate check is opposed by the targets modified level check (1d20 + character level or Hit Dice + targets Wisdom bonus [if any] + targets modifiers on saves against fear). If you beat your targets check result, you may treat the target as friendly, but only for the purpose of actions taken while it remains intimidated. (That is, the target retains its normal attitude, but will chat, advise, offer limited help, or advocate on your behalf while intimidated. See the Diplomacy skill, above, for additional details.) The effect lasts as long as the target remains in your presence, and for 1d6*10 minutes afterward. After this time, the targets default attitude toward you shifts to unfriendly (or, if normally unfriendly, to hostile).";
        //"因人而异。改变他人的行为需要 1 分钟的互动。在战斗中恐吓对手是一个标准动作。";
        action = "Varies. Changing anothers behavior requires 1 minute of interaction. Intimidating an opponent in combat is a standard action.";
    }

    //跳跃
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
        //"DC 和你可以跨越的距离根据你尝试的跳跃类型而有所不同（见下文）。你的跳跃检定会被你的速度修改。如果你的速度是 30 英尺，那么基于速度的修改器不会应用于 检查。如果你的速度小于 30 英尺，你每 10 英尺小于 30 英尺的速度受到 -6 减值。如果你的速度大于 30 英尺，你在 30 英尺以外每 10 英尺获得 +4 加值 . 此处给出的所有跳跃 DC 都假定您获得了跑步开始，这要求您在尝试跳跃之前沿直线移动至少 20 英尺。如果您没有获得跑步开始，则跳跃的 DC 加倍。距离 通过跳跃移动被计入您在一轮中的正常最大移动量。如果您在跳跃方面有等级并且您成功通过了跳跃检定，则您的脚着地（在适当的情况下）。如果您尝试未经训练的跳跃检定，除非 你击败了 DC 5 或更多。”;
        check = "The DC and the distance you can cover vary according to the type of jump you are attempting (see below). Your Jump check is modified by your speed. If your speed is 30 feet then no modifier based on speed applies to the check. If your speed is less than 30 feet, you take a -6 penalty for every 10 feet of speed less than 30 feet. If your speed is greater than 30 feet, you gain a +4 bonus for every 10 feet beyond 30 feet. All Jump DCs given here assume that you get a running start, which requires that you move at least 20 feet in a straight line before attempting the jump. If you do not get a running start, the DC for the jump is doubled. Distance moved by jumping is counted against your normal maximum movement in a round. If you have ranks in Jump and you succeed on a Jump check, you land on your feet (when appropriate). If you attempt a Jump check untrained, you land prone unless you beat the DC by 5 or more.";
        //"无。你的移动中包含跳跃检查，所以它是移动动作的一部分。";
        action = "None. A Jump check is included in your movement, so it is part of a move action.";
    }
    
    //知识
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
        //"在你的研究领域内回答一个问题的 DC 为 10（对于非常简单的问题）、15（对于基本问题）或 20 到 30（对于非常棘手的问题）。在很多情况下，你可以使用这个技能 识别怪物及其特殊能力或弱点。一般来说，这种检定的 DC 等于 10 + 怪物 HD。一次成功检定可以让你记住一些关于该怪物的有用信息。每 5 点检定 结果超过了 DC，你又想起了另一条有用的信息。”;
        check = "Answering a question within your field of study has a DC of 10 (for really easy questions), 15 (for basic questions), or 20 to 30 (for really tough questions). In many cases, you can use this skill to identify monsters and their special powers or vulnerabilities. In general, the DC of such a check equals 10 + the monsters HD. A successful check allows you to remember a bit of useful information about that monster. For every 5 points by which your check result exceeds the DC, you recall another piece of useful information.";
        //"通常没有。在大多数情况下，进行知识检定不会采取行动——你只是知道答案，或者你不知道。";
        action = "Usually none. In most cases, making a Knowledge check doesnt take an action-you simply know the answer or you dont.";
    }

    //聆听
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
        //"您的聆听检定要么是针对反映您可能听到的噪音有多安静的 DC 进行的，要么是针对您的目标进行的静默检定。在人们试图保持安静的情况下， 表格可以用静默移动检查代替，在这种情况下，指示的 DC 将是他们的平均检查结果。";
        check = "Your Listen check is either made against a DC that reflects how quiet the noise is that you might hear, or it is opposed by your targets Move Silently check. In the case of people trying to be quiet, the DCs given on the table could be replaced by Move Silently checks, in which case the indicated DC would be their average check result.";
        //"Varies 你以前没听过是一个移动动作。";
        action = "Varies. Every time you have a chance to hear something in a reactive manner (such as when someone makes a noise or you move into a new area), you can make a Listen check without using an action. Trying to hear something you failed to hear previously is a move action.";
    }

    //潜行
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
        //"你的Move Silently检定与可能听到你说话的人的Listen检定相反。你可以以正常速度的二分之一移动而不受惩罚。当移动速度大于二分之一但小于全速时 速度，你会受到 -5 的惩罚。在跑步或充电时几乎不可能安静地移动（-20 惩罚）。嘈杂的表面，如沼泽或灌木丛，很难安静地穿过。当你试图偷偷穿过这样的表面时 ，你的静默移动检定受到如下所示的惩罚。";
        check = "Your Move Silently check is opposed by the Listen check of anyone who might hear you. You can move up to one-half your normal speed at no penalty. When moving at a speed greater than one-half but less than your full speed, you take a -5 penalty. Its practically impossible (-20 penalty) to move silently while running or charging. Noisy surfaces, such as bogs or undergrowth, are tough to move silently across. When you try to sneak across such a surface, you take a penalty on your Move Silently check as indicated below.";
        //"无。你的移动或其他活动中包含了一个悄悄移动检查，所以它是另一个动作的一部分。";
        action = "None. A Move Silently check is included in your movement or other activity, so it is part of another action.";
    }

    //开锁
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
        //"打开锁的 DC 从 20 到 40 不等，具体取决于锁的质量，如下表所示。";
        check = "The DC for opening a lock varies from 20 to 40, depending on the quality of the lock, as given on the table below.";
        //"开锁是一个整轮动作。";
        action = "Opening a lock is a full-round action.";
    }

    //表演
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
        //"你可以用你的才华和技巧给观众留下深刻印象。";
        check = "You can impress audiences with your talent and skill.";
        //"因人而异。试图通过在公共场合玩耍来赚钱需要从晚上工作到一整天的表演。";
        action = "Varies. Trying to earn money by playing in public requires anywhere from an evenings work to a full days performance.";
    }

    //专业
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
        //"你可以练习你的交易并过上体面的生活，每周专注工作赚取大约一半的职业支票结果金币。你知道如何使用你的交易工具，如何执行专业的日常任务，如何 监督帮手，以及如何处理常见问题。”；
        check = "You can practice your trade and make a decent living, earning about half your Profession check result in gold pieces per week of dedicated work. You know how to use the tools of your trade, how to perform the professions daily tasks, how to supervise helpers, and how to handle common problems.";
        //"不适用。单张支票通常代表一周的工作。";
        action = "Not applicable. A single check generally represents a week of work.";
    }

    //骑术
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
        //"典型的骑乘动作不需要检查。你可以毫无问题地骑马、上马、骑马和下马。";
        check = "Typical riding actions dont require checks. You can saddle, mount, ride, and dismount from a mount without a problem.";
        //"变化。正常上马或下马是一个移动动作。其他检查是移动动作、自由动作或根本没有动作，如上所述。";
        action = "Varies. Mounting or dismounting normally is a move action. Other checks are a move action, a free action, or no action at all, as noted above.";
    }

    //搜索
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
        //"您通常必须在要搜索的物体或表面 10 英尺内。下表给出了涉及搜索技能的典型任务的 DC。";
        check = "You generally must be within 10 feet of the object or surface to be searched. The table below gives DCs for typical tasks involving the Search skill.";
        //"搜索一个 5 英尺乘 5 英尺的区域或一边 5 英尺的货物需要一个整轮动作。";
        action = "It takes a full-round action to search a 5-foot-by-5-foot area or a volume of goods 5 feet on a side.";
    }

    //察言观色
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
        //"一次成功的检定可以让你避免被诈唬。你也可以使用这个技能来确定什么时候“有事情发生”（也就是说，有一些奇怪的事情正在发生）或评估某人的可信度。";
        check = "A successful check lets you avoid being bluffed. You can also use this skill to determine when 'something is up' (that is, something odd is going on) or to assess someones trustworthiness.";
        //"尝试使用 Sense Motive 获取信息通常至少需要 1 分钟，您可能会花费一整晚的时间来了解周围的人。";
        action = "Trying to gain information with Sense Motive generally takes at least 1 minute, and you could spend a whole evening trying to get a sense of the people around you.";
    }

    //手上功夫
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
        //"一个 DC 10 的手上功夫检定让你可以用手掌握住一个硬币大小的无人看管的物体。执行一个小骗术，例如让硬币消失，也有一个 DC 10，除非观察者决定注意哪里 项目去了。”;
        check = "A DC 10 Sleight of Hand check lets you palm a coin-sized, unattended object. Performing a minor feat of legerdemain, such as making a coin disappear, also has a DC of 10 unless an observer is determined to note where the item went.";
        //"任何手上功夫检定通常是一个标准动作。但是，你可以通过在检定上受到-20 的惩罚来作为一个自由动作进行手上功夫检定。";
        action = "Any Sleight of Hand check normally is a standard action. However, you may perform a Sleight of Hand check as a free action by taking a -20 penalty on the check.";
    }

    //语言
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
        //"不适用。";
        check = "Not applicable.";
        action = "Not applicable.";
    }

    //辨识法术
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
        //"您可以识别法术和魔法效果。与各种任务相关的法术辨识检查的 DC 总结在下表中。";
        check = "You can identify spells and magic effects. The DCs for Spellcraft checks relating to various tasks are summarized on the table below.";
        //变化
        action = "Varies.";
    }

    //侦察
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
        //"侦察技能主要用于检测躲藏起来的角色或生物。通常，你的侦察检定与试图不被人看到的生物的隐藏检定相反。有时一个生物不是故意躲藏，但仍然很难被看到 ，因此必须进行一次成功的侦察才能注意到它。侦察结果高于 20 通常会让你意识到附近有一个隐形生物，尽管你实际上看不到它。";
        check = "The Spot skill is used primarily to detect characters or creatures who are hiding. Typically, your Spot check is opposed by the Hide check of the creature trying not to be seen. Sometimes a creature isnt intentionally hiding but is still difficult to see, so a successful Spot check is necessary to notice it. A Spot check result higher than 20 generally lets you become aware of an invisible creature near you, though you cant actually see it.";
        //"变化。每次你有机会以反应方式发现某物时，你都可以不使用动作进行侦察。";
        action = "Varies. Every time you have a chance to spot something in a reactive manner you can make a Spot check without using an action.";
    }
    
    //生存
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
        //"你可以保证自己和他人的安全并在野外觅食。下表给出了需要生存检查的各种任务的 DC。";
        check = "You can keep yourself and others safe and fed in the wild. The table below gives the DCs for various tasks that require Survival checks.";
        //"变化。为了在野外相处或获得上表中提到的强韧豁免奖励，你每 24 小时进行一次生存检定。";
        action = "Varies. For getting along in the wild or for gaining the Fortitude save bonus noted in the table above, you make a Survival check once every 24 hours.";
    }

    //游泳
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
        //"当你在水中时，每轮进行一次游泳检定。成功意味着你可以以你速度的二分之一（作为整轮动作）或四分之一的速度（作为移动动作）游泳 ).如果你失败4或更少，你就不会在水中前进。如果你失败5或更多，你会进入水下。";
        check = "Make a Swim check once per round while you are in the water. Success means you may swim at up to one-half your speed (as a full-round action) or at one-quarter your speed (as a move action). If you fail by 4 or less, you make no progress through the water. If you fail by 5 or more, you go underwater.";
        //"一次成功的游泳检定可以让你以你的四分之一速度作为一个移动动作或以你一半的速度作为一个整轮动作游泳。";
        action = "A successful Swim check allows you to swim one-quarter of your speed as a move action or one-half your speed as a full-round action.";
    }
    
    //翻滚
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
        //"当你跌倒或翻越对手时，你可以轻轻着陆。你也可以翻滚来娱乐观众（就像使用表演技能一样）。涉及翻滚技能的各种任务的 DC 在下表中给出。";
        check = "You can land softly when you fall or tumble past opponents. You can also tumble to entertain an audience (as though using the Perform skill). The DCs for various tasks involving the Tumble skill are given on the table below.";
        //"不适用。翻滚是移动的一部分，所以翻滚检查是移动动作的一部分。";
        action = "Not applicable. Tumbling is part of movement, so a Tumble check is part of a move action.";
    }

    //使用魔法装置
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
        //"您可以使用此技能来阅读法术或激活魔法物品。使用魔法装置可以让您使用魔法物品，就好像您拥有另一个职业的法术能力或职业特征一样，就好像您是不同的种族一样， 或者就好像你是一个不同的阵营。每次激活魔杖之类的设备时，你都要进行一次使用魔法装置检查。如果你正在使用检查来模拟阵营或其他一些持续的品质，你需要 每小时进行一次相关的使用魔法装置检查。";
        check = "You can use this skill to read a spell or to activate a magic item. Use Magic Device lets you use a magic item as if you had the spell ability or class features of another class, as if you were a different race, or as if you were of a different alignment. You make a Use Magic Device check each time you activate a device such as a wand. If you are using the check to emulate an alignment or some other quality in an ongoing manner, you need to make the relevant Use Magic Device check once per hour.";
        //"无。使用魔法装置检查是作为激活魔法物品所需动作（如果有）的一部分进行的。";
        action = "None. The Use Magic Device check is made as part of the action (if any) required to activate the magic item.";
    }

    //绳技
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
        //"固定抓钩需要使用绳索检定（DC 10，抓钩每投掷 10 英尺的距离 +2，在 50 英尺处的最大 DC 为 20。失败 4 或更少表明钩子 没能接住摔倒，让你再试一次。失败5或更多表示抓钩最初抓住，但在支撑重量1d4轮后松动。这个检查是秘密进行的，所以你不知道绳子是否会 保持体重。”;
        check = "Securing a grappling hook requires a Use Rope check (DC 10, +2 for every 10 feet of distance the grappling hook is thrown, to a maximum DC of 20 at 50 feet). Failure by 4 or less indicates that the hook fails to catch and falls, allowing you to try again. Failure by 5 or more indicates that the grappling hook initially holds, but comes loose after 1d4 rounds of supporting weight. This check is made secretly, so that you dont know whether the rope will hold your weight.";
        //"因人而异。投掷抓钩是一个标准动作，会引发借机攻击。";
        action = "Varies. Throwing a grappling hook is a standard action that provokes an attack of opportunity.";
    }
}
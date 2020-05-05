Shop_Bonus - плагин позволяющий получить бонусные кредиты по команде !bonus

# Требования:
* SourceMod > 1.7 и < 1.10

# Доступные команды:
* !bonus - Получить бонусные кредиты

# Квары:
* shop_bonus_time - Через сколько секунд можно будет использовать бонус повторно? (указывать в СЕКУНДАХ, 0 = никогда)
* shop_bonus_credits - Сколько выдавать кредитов игроку?

# Подключение к бд

Mysql :

	  "credits"
    {
        "driver"      "default"
        "host"    	  ""
        "database"    ""
        "user"    	  ""
        "pass"    	  ""
    }
SqlLite:

	"credits"
	{
		"driver"			"sqlite"
		"database"			"credits"
	}

# Поддержка разработки:
* ЯндексДеньги - 410011807128321
* WebMoney - R308981403112
* Steam - https://steamcommunity.com/tradeoffer/new/?partner=137766484&token=D0iB8uno

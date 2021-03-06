#Использовать yaml

Перем Кэш;

Функция Main()
	
	ИдентификаторГруппы = Число(ПолучитьЗначение("group-id"));
	
	ВывестиВЛог(СтрШаблон(
			"group-id: %1"
			, ИдентификаторГруппы
		));
	
	
	СтрокаYAML = ПолучитьЗначениеИзФайла(
			ТекущийКаталог() + "\" + "data" + ПолучитьЗначение("group-id") + ".yaml"
		);
	
	ВывестиВЛог(СтрШаблон(
			"YAML:
			|%1"
			, СтрокаYAML
		));
	
	Если СтрокаYAML = Неопределено Тогда
		ВывестиВЛог("Данных нет, процесс завершен");
		Возврат Неопределено;
	КонецЕсли;
	
	СтрокаYAML = СтрЗаменить(СтрокаYAML, Символы.Таб, ПолучитьЗаменуТабуляции(4));
	
	ХэшКэш = ПолучитьЗначениеИзФайла(
			ТекущийКаталог() + "\" + "hash" + ПолучитьЗначение("group-id")
		);
	
	Хэш = ПолучитьХеш_CRC32(СтрокаYAML);
	
	ВывестиВЛог(СтрШаблон(
			"Хэш сохраненный: %1
			|Хеш новый:       %2"
			, ХэшКэш
			, Хэш
		));
	
	Если Хэш = ХэшКэш Тогда
		ВывестиВЛог("Изменений нет, процесс завершен");
		Возврат Неопределено;
	КонецЕсли;
	
	ПроцессорЧтения = Новый ПарсерYaml;
	Группа = ПроцессорЧтения.ПрочитатьYaml(СтрокаYAML);
	
	КоллекцияУровнейДоступа = Новый Соответствие;
	КоллекцияУровнейДоступа["Owner (50)"] = 40;
	КоллекцияУровнейДоступа["Maintainer (40)"] = 40;
	КоллекцияУровнейДоступа["Developer (30)"] = 30;
	КоллекцияУровнейДоступа["Reporter (20)"] = 20;
	КоллекцияУровнейДоступа["Guest (10)"] = 10;
	КоллекцияУровнейДоступа["Owner"] = 40;
	КоллекцияУровнейДоступа["Maintainer"] = 40;
	КоллекцияУровнейДоступа["Developer"] = 30;
	КоллекцияУровнейДоступа["Reporter"] = 20;
	КоллекцияУровнейДоступа["Guest"] = 10;
	КоллекцияУровнейДоступа["50"] = 40;
	КоллекцияУровнейДоступа["40"] = 40;
	КоллекцияУровнейДоступа["30"] = 30;
	КоллекцияУровнейДоступа["20"] = 20;
	КоллекцияУровнейДоступа["10"] = 10;
	КоллекцияУровнейДоступа[50] = 40;
	КоллекцияУровнейДоступа[40] = 40;
	КоллекцияУровнейДоступа[30] = 30;
	КоллекцияУровнейДоступа[20] = 20;
	КоллекцияУровнейДоступа[10] = 10;
	
	ВывестиВЛог("Построение списка проектов...");
	
	КоллекцияПроектов = ПолучитьКоллекциюПроектов(Группа, КоллекцияУровнейДоступа);
	
	ВывестиВЛог("Построение списка проектов... Готово");
	
	
	ИдентификаторыСотрудников = Новый Соответствие;
	
	ВывестиВЛог("Обработка списка проектов...");
	
	Для Каждого Элемент Из КоллекцияПроектов Цикл
		
		ВывестиВЛог(СтрШаблон(
				"Обработка проекта: %1 %2"
				, Элемент.Ключ["id"]
				, Элемент.Ключ["name"]
			));
		
		ВывестиВЛог("Построение списка пользователей...");
		
		ТаблицаПользователей = ПолучитьТаблицуПользователей(
				Элемент.Ключ["id"],
				Элемент.Значение,
				ИдентификаторыСотрудников,
				КоллекцияУровнейДоступа
			);
		
		ТаблицаПользователей = ЗаполнитьИдентификаторыСотрудников(
				ТаблицаПользователей,
				ИдентификаторыСотрудников
			);
		
		ВывестиВЛог("Построение списка пользователей... Готово");
		
		
		ВывестиВЛог("Установка прав доступа пользователей...");
		ВывестиВЛог(СтрШаблон(
				"Количество изменений: %1"
				, ТаблицаПользователей.Количество()
			));
		
		УстановитьПраваДоступаПользователейПроектов(
			Элемент.Ключ["id"],
			ТаблицаПользователей
		);
		
		ВывестиВЛог("Установка прав доступа пользователей... Готово");
		
	КонецЦикла;
	
	ВывестиВЛог("Обработка списка проектов... Готово");
	
	ЗаписатьСтрокуВФайл(
		ТекущийКаталог() + "\" + "hash" + ПолучитьЗначение("group-id"),
		ПолучитьХеш_CRC32(СтрокаYAML)
	);
	
КонецФункции

Функция ПолучитьКоллекциюПроектов(Группа, КоллекцияУровнейДоступа)
	
	КоллекцияГрупп = Новый Соответствие;
	КоллекцияПроектов = Новый Соответствие;
	
	УровеньДоступаПоУмолчанию = 30;
	
	КоллекцияГрупп[Группа] = ПолучитьКоллекциюСотрудников(
			Группа["members"],
			КоллекцияУровнейДоступа,
			УровеньДоступаПоУмолчанию
		);
	
	ОчередьГрупп = Новый Массив;
	ОчередьГрупп.Добавить(Группа);
	
	Пока ОчередьГрупп.Количество() > 0 Цикл
		
		Группа = ОчередьГрупп[0];
		
		ОчередьГрупп.Удалить(0);
		
		Если Группа["subgroups"] <> Неопределено Тогда
			
			Для Каждого Подгруппа Из Группа["subgroups"] Цикл
				
				КоллекцияГрупп[Подгруппа] = ОбъединитьКоллекцииСотрудников(
						ПолучитьКоллекциюСотрудников(
							Подгруппа["members"],
							КоллекцияУровнейДоступа,
							УровеньДоступаПоУмолчанию
						),
						КоллекцияГрупп[Группа]
					);
				
				ОчередьГрупп.Добавить(Подгруппа);
				
			КонецЦикла;
			
		КонецЕсли;
		
	КонецЦикла;
	
	Для Каждого Элемент Из КоллекцияГрупп Цикл
		
		Если Элемент.Ключ["projects"] <> Неопределено Тогда
			
			Для Каждого Проект Из Элемент.Ключ["projects"] Цикл
				
				КоллекцияПроектов[Проект] = ОбъединитьКоллекцииСотрудников(
						ПолучитьКоллекциюСотрудников(
							Проект["members"],
							КоллекцияУровнейДоступа,
							УровеньДоступаПоУмолчанию
						),
						Элемент.Значение
					);
				
			КонецЦикла;
			
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат КоллекцияПроектов;
	
КонецФункции

Функция ПолучитьТаблицуПользователей(ИдентификаторПроекта, СписокСотрудниковПроекта, ИдентификаторыСотрудников, КоллекцияУровнейДоступа)
	
	Действия = Новый Структура;
	Действия.Вставить("Удалить", 1);
	Действия.Вставить("Добавить", 2);
	Действия.Вставить("Изменить", 3);
	
	ТаблицаПользователей = Новый ТаблицаЗначений;
	ТаблицаПользователей.Колонки.Добавить("id");
	ТаблицаПользователей.Колонки.Добавить("username");
	ТаблицаПользователей.Колонки.Добавить("access_level");
	ТаблицаПользователей.Колонки.Добавить("Действие");
	
	ТаблицаПользователей.Очистить();
	
	Информация = РасшифроватьJson(ВыполнитьЗапрос("Get",
				"projects/" + ИдентификаторПроекта + "/members/all?per_page=100"
			));
	
	Пользователи = Новый Соответствие;
	
	Для Каждого ЭлементИнформации Из Информация Цикл
		Пользователи[ЭлементИнформации.username] = КоллекцияУровнейДоступа[ЭлементИнформации.access_level];
		ИдентификаторыСотрудников[ЭлементИнформации.username] = ЭлементИнформации.id;
	КонецЦикла;
	
	Для Каждого Сотрудник Из СписокСотрудниковПроекта Цикл
		
		Если Пользователи[Сотрудник.Ключ] = Неопределено Тогда
			
			СтрокаТаблицы = ТаблицаПользователей.Добавить();
			СтрокаТаблицы.username = Сотрудник.Ключ;
			СтрокаТаблицы.access_level = Сотрудник.Значение;
			СтрокаТаблицы.Действие = Действия.Добавить;
			
		ИначеЕсли Пользователи[Сотрудник.Ключ] <> Сотрудник.Значение Тогда
			
			СтрокаТаблицы = ТаблицаПользователей.Добавить();
			СтрокаТаблицы.username = Сотрудник.Ключ;
			СтрокаТаблицы.access_level = Сотрудник.Значение;
			СтрокаТаблицы.Действие = Действия.Изменить;
			
		Иначе
			// Не меняем уровень доступа сотрудника
		КонецЕсли;
		
	КонецЦикла;
	
	Для Каждого Сотрудник Из Пользователи Цикл
		
		Если СписокСотрудниковПроекта[Сотрудник.Ключ] = Неопределено Тогда
			
			СтрокаТаблицы = ТаблицаПользователей.Добавить();
			СтрокаТаблицы.username = Сотрудник.Ключ;
			СтрокаТаблицы.Действие = Действия.Удалить;
			
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат ТаблицаПользователей;
	
КонецФункции

Функция ЗаполнитьИдентификаторыСотрудников(ТаблицаПользователей, ИдентификаторыСотрудников)
	
	Для Каждого СтрокаТаблицы Из ТаблицаПользователей Цикл
		
		СтрокаТаблицы.id = ИдентификаторыСотрудников[СтрокаТаблицы.username];
		
		Если СтрокаТаблицы.id = Неопределено Тогда
			
			Информация = РасшифроватьJson(ВыполнитьЗапрос("Get",
						"users?username=" + СтрокаТаблицы.username
					));
			
			Если ТипЗнч(Информация) = Тип("Массив") И Информация.Количество() > 0 Тогда
				
				СтрокаТаблицы.id = Информация[0].id;
				
				ИдентификаторыСотрудников[СтрокаТаблицы.username] = СтрокаТаблицы.id;
				
			КонецЕсли;
			
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат ТаблицаПользователей;
	
КонецФункции

Функция УстановитьПраваДоступаПользователейПроектов(ИдентификаторПроекта, ТаблицаПользователей)
	
	Действия = Новый Структура;
	Действия.Вставить("Удалить", 1);
	Действия.Вставить("Добавить", 2);
	Действия.Вставить("Изменить", 3);
	
	Для Каждого СтрокаТаблицы Из ТаблицаПользователей Цикл
		
		Если СтрокаТаблицы.id = Неопределено Тогда
			Продолжить;
		КонецЕсли;
		
		Если СтрокаТаблицы.Действие = Действия.Удалить Тогда
			
			Информация = РасшифроватьJson(ВыполнитьЗапрос("DELETE",
						"projects/" + ИдентификаторПроекта + "/members/" + СтрокаТаблицы.id
					));
			
		ИначеЕсли СтрокаТаблицы.Действие = Действия.Добавить Тогда
			
			Информация = РасшифроватьJson(ВыполнитьЗапрос("POST",
						"projects/" + ИдентификаторПроекта + "/members?user_id=" + СтрокаТаблицы.id + "&access_level=" + СтрокаТаблицы.access_level
					));
			
		ИначеЕсли СтрокаТаблицы.Действие = Действия.Изменить Тогда
			
			Информация = РасшифроватьJson(ВыполнитьЗапрос("PUT",
						"projects/" + ИдентификаторПроекта + "/members/" + СтрокаТаблицы.id + "?access_level=" + СтрокаТаблицы.access_level
					));
		Иначе
			
			ВывестиВЛог(СтрШаблон(
					"Непредусмотренное значение колонки ""Действие"": %1"
					, СтрокаТаблицы.Действие
				));
			
		КонецЕсли;
		
	КонецЦикла;
	
КонецФункции

Функция ПолучитьЗначение(Ключ)
	
	Значение = Раскэшировать(Ключ);
	
	Если Значение = Неопределено Тогда
		
		Значение = ПолучитьАргументКоманднойСтроки("-" + Ключ);
		
		Если Значение = Неопределено Тогда
			
			Значение = ПолучитьЗначениеИзФайла(ТекущийКаталог() + "\" + Ключ);
			
		КонецЕсли;
		
		Закэшировать(Ключ, Значение);
		
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции

Функция ПолучитьАргументКоманднойСтроки(Ключ)
	
	Индекс = АргументыКоманднойСтроки.Найти(Ключ);
	
	Если Индекс = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Если АргументыКоманднойСтроки.ВГраница() <= Индекс Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Возврат АргументыКоманднойСтроки[Индекс + 1];
	
КонецФункции

Функция ПолучитьЗначениеИзФайла(ПолноеИмяФайла)
	
	Файл = Новый Файл(ПолноеИмяФайла);
	
	Если Не Файл.Существует() Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Чтение = Новый ЧтениеТекста(ПолноеИмяФайла);
	
	Значение = Чтение.Прочитать();
	
	Чтение.Закрыть();
	
	Возврат Значение;
	
КонецФункции

Функция ЗаписатьСтрокуВФайл(ПолноеИмяФайла, Строка)
	
	Запись = Новый ЗаписьТекста(ПолноеИмяФайла);
	
	Запись.Записать(Строка);
	
	Запись.Закрыть();
	
КонецФункции

Функция Закэшировать(Ключ, Значение)
	
	Если Кэш = Неопределено Тогда
		Кэш = Новый Соответствие;
	КонецЕсли;
	
	Кэш[Ключ] = Значение;
	
	Возврат ЭтотОбъект;
	
КонецФункции

Функция Раскэшировать(Ключ)
	
	Если Кэш = Неопределено Тогда
		Кэш = Новый Соответствие;
	КонецЕсли;
	
	Возврат Кэш[Ключ];
	
КонецФункции

Функция ВыполнитьЗапрос(Метод, ТекстЗапроса)
	
	URL = "https://gitlab.com/api/v4/" + ТекстЗапроса;
	
	Соединение = Новый HTTPСоединение(URL, , , , , 100);
	
	Запрос = Новый HTTPЗапрос;
	Запрос.Заголовки = Новый Соответствие;
	Запрос.Заголовки.Вставить("PRIVATE-TOKEN", ПолучитьЗначение("private-token"));
	
	Ответ = Соединение.ВызватьHTTPМетод(Метод, Запрос);
	
	ВывестиВЛог(СтрШаблон(
			"
			|%1 /%2
			|-->
			|Код ответа: %3
			|Ответ:
			|%4"
			, Метод
			, ТекстЗапроса
			, Ответ.КодСостояния
			, Ответ.ПолучитьТелоКакСтроку()
		));
	
	Если Ответ.КодСостояния <> 200 Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Возврат Ответ.ПолучитьТелоКакСтроку();
	
КонецФункции

Функция РасшифроватьJson(СтрокаJson)
	
	Если СтрокаJson = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Чтение = Новый ЧтениеJSON;
	Чтение.УстановитьСтроку(СтрокаJson);
	
	Значение = ПрочитатьJSON(Чтение);
	
	Чтение.Закрыть();
	
	Возврат Значение;
	
КонецФункции

Функция ПолучитьЗаменуТабуляции(Знач ПробеловВТабуляцииПоУмолчанию = 4)
	
	ПробеловВТабуляции = ПолучитьЗначение("tab-spaces");
	
	Если Не ЗначениеЗаполнено(ПробеловВТабуляции) Тогда
		ПробеловВТабуляции = ПробеловВТабуляцииПоУмолчанию;
	КонецЕсли;
	
	Строка = "";
	
	Для й = 1 По ПробеловВТабуляции Цикл
		Строка = Строка + " ";
	КонецЦикла;
	
	Возврат Строка;
	
КонецФункции

Функция ПолучитьКоллекциюСотрудников(СписокСотрудников, КоллекцияУровнейДоступа, УровеньДоступаПоУмолчанию)
	
	Соответствие = Новый Соответствие;
	
	Очередь = Новый Массив;
	Очередь.Добавить(СписокСотрудников);
	
	Пока Очередь.Количество() > 0 Цикл
		
		ЭлементОчереди = Очередь[0];
		
		Очередь.Удалить(0);
		
		Если ЭлементОчереди = Неопределено Тогда
			// nothing
		ИначеЕсли ТипЗнч(ЭлементОчереди) = Тип("Массив") Тогда
			
			Для Каждого Элемент Из ЭлементОчереди Цикл
				Очередь.Добавить(Элемент);
			КонецЦикла;
			
		ИначеЕсли ТипЗнч(ЭлементОчереди) = Тип("Структура")
			Или ТипЗнч(ЭлементОчереди) = Тип("ФиксированнаяСтруктура")
			Или ТипЗнч(ЭлементОчереди) = Тип("Соответствие")
			Или ТипЗнч(ЭлементОчереди) = Тип("ФиксированноеСоответствие") Тогда
			
			Для Каждого Элемент Из ЭлементОчереди Цикл
				Если КоллекцияУровнейДоступа[Элемент.Значение] <> Неопределено Тогда
					Соответствие[Элемент.Ключ] = КоллекцияУровнейДоступа[Элемент.Значение];
				КонецЕсли;
			КонецЦикла;
			
		Иначе
			
			Соответствие[ЭлементОчереди] = УровеньДоступаПоУмолчанию;
			
		КонецЕсли;
		
	КонецЦикла;
	
	Возврат Соответствие;
	
КонецФункции

Функция ОбъединитьКоллекцииСотрудников(Коллекция1, Коллекция2)
	
	МассивКоллекций = Новый Массив;
	МассивКоллекций.Добавить(Коллекция1);
	МассивКоллекций.Добавить(Коллекция2);
	
	Объединение = Новый Соответствие;
	
	Для Каждого Коллекция Из МассивКоллекций Цикл
		Для Каждого Элемент Из Коллекция Цикл
			
			Значение = Объединение[Элемент.Ключ];
			
			Если Значение = Неопределено Тогда
				Значение = 0;
			КонецЕсли;
			
			Если Элемент.Значение Тогда
				
			КонецЕсли;
			
			Объединение[Элемент.Ключ] = Макс(Значение, Элемент.Значение);
			
		КонецЦикла;
	КонецЦикла;
	
	Возврат Объединение;
	
КонецФункции

Функция ПолучитьХеш_CRC32(СтрокаYAML)
	
	Хеширование = Новый ХешированиеДанных(ХешФункция.CRC32);
	
	Хеширование.Добавить(СтрокаYAML);
	
	Возврат Хеширование.ХешСуммаСтрокой;
	
КонецФункции

Функция ВывестиВЛог(Знач ТекстСообщения)
	
	ФайлЛога = ПолучитьЗначение("log");
	
	Если ЗначениеЗаполнено(ФайлЛога) Тогда
		
		Запись = Новый ЗаписьТекста(ФайлЛога, , , Истина);
		Запись.ЗаписатьСтроку(ТекстСообщения);
		Запись.Закрыть();
		
	КонецЕсли;
	
	Сообщить(ТекстСообщения);
	
КонецФункции

ВывестиВЛог(СтрШаблон(
		"
		|Начало
		|%1"
		, Формат(ТекущаяДата(), "ДЛФ=DT")
	));

Main();

ВывестиВЛог(СтрШаблон(
		"%1
		|Завершено
		|"
		, Формат(ТекущаяДата(), "ДЛФ=DT")
	));

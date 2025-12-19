import csv
import re
import os
from datetime import datetime
from functools import wraps
from pprint import pprint



def logger(path):
    def __logger(old_function):
        @wraps(old_function)
        def new_function(*args, **kwargs):
            result = old_function(*args, **kwargs)

            with open(path, 'a', encoding='utf-8') as f:
                f.write(
                    f'{datetime.now()} | '
                    f'{old_function.__name__} | '
                    f'args={args}, kwargs={kwargs} | '
                    f'result={result}\n'
                )

            return result
        return new_function
    return __logger


LOG_PATH = 'phonebook.log'


@logger(LOG_PATH)
def read_csv(filename):
    with open(filename, encoding="utf-8") as f:
        rows = csv.reader(f, delimiter=",")
        return list(rows)


@logger(LOG_PATH)
def normalize_fio(contacts_list):
    new_contacts = []
    for row in contacts_list:
        fio = " ".join(row[:3]).split()
        fio = (fio + ["", "", ""])[:3]
        row[0], row[1], row[2] = fio
        new_contacts.append(row)
    return new_contacts


@logger(LOG_PATH)
def format_phones(contacts):
    phone_pattern = re.compile(
        r"(\+7|8)?\s*\(?(\d{3})\)?[\s-]*(\d{3})[\s-]*(\d{2})[\s-]*(\d{2})"
        r"(?:\s*\(?(доб\.?)\s*(\d+)\)?)?"
    )

    def format_phone(phone):
        if not phone:
            return ""
        return phone_pattern.sub(
            lambda m: f"+7({m.group(2)}){m.group(3)}-{m.group(4)}-{m.group(5)}"
                      + (f" доб.{m.group(7)}" if m.group(7) else ""),
            phone
        )

    for row in contacts:
        row[5] = format_phone(row[5])

    return contacts


@logger(LOG_PATH)
def merge_duplicates(contacts):
    merged = {}
    for row in contacts:
        key = (row[0], row[1])
        if key not in merged:
            merged[key] = row
        else:
            for i in range(len(row)):
                if not merged[key][i] and row[i]:
                    merged[key][i] = row[i]
    return list(merged.values())


@logger(LOG_PATH)
def save_csv(filename, data):
    with open(filename, "w", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter=',')
        writer.writerows(data)



@logger(LOG_PATH)
def main():
    if os.path.exists(LOG_PATH):
        os.remove(LOG_PATH)

    contacts = read_csv("phonebook_raw.csv")
    pprint(contacts)

    contacts = normalize_fio(contacts)
    contacts = format_phones(contacts)
    result = merge_duplicates(contacts)

    pprint(result)

    save_csv("phonebook.csv", result)


if __name__ == '__main__':
    main()

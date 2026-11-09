/*
 * nautilus-copy-path: add a Copy Path item to the Nautilus selection menu.
 *
 * Copyright (C) 2026
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, version 3.
 */

#include <nautilus-extension.h>
#include <gtk/gtk.h>

typedef struct {
    GObject parent_instance;
} CopyPathProvider;

typedef struct {
    GObjectClass parent_class;
} CopyPathProviderClass;

static void menu_provider_iface_init(NautilusMenuProviderInterface *iface);

G_DEFINE_DYNAMIC_TYPE_EXTENDED(CopyPathProvider, copy_path_provider, G_TYPE_OBJECT, 0,
                               G_IMPLEMENT_INTERFACE_DYNAMIC(NAUTILUS_TYPE_MENU_PROVIDER,
                                                             menu_provider_iface_init))

static void
copy_path_provider_class_init(CopyPathProviderClass *klass)
{
    (void) klass;
}

static void
copy_path_provider_class_finalize(CopyPathProviderClass *klass)
{
    (void) klass;
}

static void
copy_path_provider_init(CopyPathProvider *self)
{
    (void) self;
}

static void
on_copy_path_activate(NautilusMenuItem *item, gpointer user_data)
{
    GList *files = g_object_get_data(G_OBJECT(item), "copy-path-files");
    GString *text = g_string_new(NULL);

    (void) user_data;

    for (GList *l = files; l != NULL; l = l->next) {
        GFile *location = nautilus_file_info_get_location(l->data);
        if (location == NULL) {
            continue;
        }
        char *path = g_file_get_path(location);
        if (path != NULL) {
            if (text->len > 0) {
                g_string_append_c(text, '\n');
            }
            g_string_append(text, path);
            g_free(path);
        }
        g_object_unref(location);
    }

    if (text->len > 0) {
        GtkClipboard *clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
        gtk_clipboard_set_text(clipboard, text->str, -1);
        gtk_clipboard_store(clipboard);
    }
    g_string_free(text, TRUE);
}

static GList *
get_file_items(NautilusMenuProvider *provider, GtkWidget *window, GList *files)
{
    gboolean has_local_file = FALSE;

    (void) provider;
    (void) window;

    if (files == NULL) {
        return NULL;
    }

    for (GList *l = files; l != NULL; l = l->next) {
        GFile *location = nautilus_file_info_get_location(l->data);
        if (location == NULL) {
            continue;
        }
        char *scheme = g_file_get_uri_scheme(location);
        if (g_strcmp0(scheme, "file") == 0) {
            has_local_file = TRUE;
        }
        g_free(scheme);
        g_object_unref(location);
        if (has_local_file) {
            break;
        }
    }

    if (!has_local_file) {
        return NULL;
    }

    gboolean multiple = g_list_length(files) > 1;
    NautilusMenuItem *item = nautilus_menu_item_new("CopyPathProvider::copy_path",
                                                    multiple ? "Copy Paths" : "Copy Path",
                                                    "Copy the selected file path to the clipboard",
                                                    "edit-copy");
    g_object_set_data_full(G_OBJECT(item), "copy-path-files",
                           nautilus_file_info_list_copy(files),
                           (GDestroyNotify) nautilus_file_info_list_free);
    g_signal_connect(item, "activate", G_CALLBACK(on_copy_path_activate), NULL);
    return g_list_append(NULL, item);
}

static GList *
get_background_items(NautilusMenuProvider *provider, GtkWidget *window,
                     NautilusFileInfo *current_folder)
{
    (void) provider;
    (void) window;
    (void) current_folder;
    return NULL;
}

static void
menu_provider_iface_init(NautilusMenuProviderInterface *iface)
{
    iface->get_file_items = get_file_items;
    iface->get_background_items = get_background_items;
}

static GType provider_types[1];

void
nautilus_module_initialize(GTypeModule *module)
{
    copy_path_provider_register_type(module);
    provider_types[0] = copy_path_provider_get_type();
}

void
nautilus_module_shutdown(void)
{
}

void
nautilus_module_list_types(const GType **types, int *num_types)
{
    *types = provider_types;
    *num_types = G_N_ELEMENTS(provider_types);
}

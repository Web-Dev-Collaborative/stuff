package com.netflix.fabricator.guice.mapping;

import com.google.common.base.Preconditions;
import com.google.inject.Injector;
import com.netflix.fabricator.BindingComponentFactory;
import com.netflix.fabricator.ConfigurationNode;

import java.lang.reflect.Method;

/**
 * Created by hyuan on 1/17/14.
 */
public class CompositeNoExistingBinding implements BindingReslove {
    private final String propertyName;
    private final BindingComponentFactory<?> provider;

    public CompositeNoExistingBinding(String propertyName, BindingComponentFactory<?> provider) {
        Preconditions.checkNotNull(propertyName);
        Preconditions.checkNotNull(provider);
        
        this.propertyName = propertyName;
        this.provider = provider;
    }

    @Override
    public boolean execute(String name, Object obj, ConfigurationNode node, Class<?> argType, Injector injector, Method method) throws Exception {
        if (node != null) {
            Object subObject = provider.get().create(node);
            method.invoke(obj, subObject);
        }
        return true;
    }
}
